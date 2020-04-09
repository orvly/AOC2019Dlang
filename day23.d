module day23;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

// ******** INTCODE COMPUTER ************

enum RunState { Running, Paused, Finished };
struct Program {
    int id;
    long[long] memAA;
    long ip = 0;
    long relativeBase;
    RunState runState = RunState.Running;
    long delegate(ref Program me) getInput;
    void delegate(ref Program me, long output) doOutput;
}

void resetIntCode(ref Program pr, long[long] memory) {
    // pr.memAA = memory.dup;
    foreach(kv; memory.byKeyValue) {
        pr.memAA[kv.key] = kv.value;
    }
    pr.ip = 0;
    pr.relativeBase = 0;
    pr.runState = RunState.Running;
}

ref long mem(ref Program p, long addr) {
    return p.memAA.require(addr, 0);
}

ref long getLValue(ref Program p, int numOperand) {
    int mode;
    if (numOperand == 1)
        mode = p.mem(p.ip) / 100 % 10;
    else if (numOperand == 2)
        mode = p.mem(p.ip) / 1000 % 10;
    else if (numOperand == 3)
        mode = p.mem(p.ip) / 10000 % 10;
    // io.writeln("operand:", numOperand, ", mode:", mode);
    switch(mode) {
        case 0: return p.mem(p.mem(p.ip + numOperand));
        case 2: return p.mem(p.mem(p.ip + numOperand) + p.relativeBase);
        default: throw new Exception("Error in mode: " ~ mode.to!string);
    }
}

long getValue(ref Program p, int numOperand) {
    int mode;
    if (numOperand == 1)
        mode = p.mem(p.ip) / 100 % 10;
    else if (numOperand == 2)
        mode = p.mem(p.ip) / 1000 % 10;
    else if (numOperand == 3)
        mode = p.mem(p.ip) / 10000 % 10;
    if (mode != 1 && mode != 0 && mode != 2)
        throw new Exception("Error in mode");
    // io.writeln("operand:", numOperand, ", mode:", mode);
    switch(mode) {
        case 0: return p.mem(p.mem(p.ip + numOperand));
        case 1: return p.mem(p.ip + numOperand);
        case 2: return p.mem(p.mem(p.ip + numOperand) + p.relativeBase);
        default: throw new Exception("Error in mode: " ~ mode.to!string);
    }
    // return (mode == 1) ? p.mem(p.ip + numOperand) : p.mem(p.mem(p.ip + numOperand));
}

alias Runner = long function(ref Program);
immutable Runner[int] runners;

shared static this() {
    import std.exception: assumeUnique;
    Runner[int] temp;
    temp[1] = (ref Program p) { 
        p.getLValue(3) = p.getValue(1) + p.getValue(2);
        return p.ip + 4;
    };
    temp[2] = (ref Program p) { 
        p.getLValue(3) = p.getValue(1) * p.getValue(2);
        return p.ip + 4;
    };
    temp[3] = (ref Program p) {
        auto input = p.getInput(p);
        p.getLValue(1) = input;
        return p.ip + 2; 
    };
    temp[4] = (ref Program p) {
        p.doOutput(p, getValue(p, 1));
        return p.ip + 2;
    };
    temp[5] = (ref Program p) {
        return (getValue(p, 1) != 0) ? getValue(p, 2) : (p.ip + 3);
    };
    temp[6] = (ref Program p) {
        return (getValue(p, 1) == 0) ? getValue(p, 2) : (p.ip + 3);
    };
    temp[7] = (ref Program p) {
        // p.mem(p.mem(p.ip + 3)) = (getValue(p, 1) < getValue(p,2)) ? 1 : 0;
        p.getLValue(3) = (getValue(p, 1) < getValue(p,2)) ? 1 : 0;
        return p.ip + 4;
    };
    temp[8] = (ref Program p) {
        // p.mem(p.mem(p.ip + 3)) = (getValue(p, 1) == getValue(p,2 )) ? 1 : 0;
        p.getLValue(3) = (getValue(p, 1) == getValue(p,2 )) ? 1 : 0;
        return p.ip + 4;
    };
    temp[9] = (ref Program p) {
        long delta = getValue(p, 1);
        p.relativeBase += getValue(p, 1);
        return p.ip + 2;
    };
    temp[99] = (ref Program p) {
        p.runState = RunState.Finished;
        return p.ip;
    }; 
    
    runners = assumeUnique(temp);
}

void runProgram(ref Program p) {
    while(p.runState == RunState.Running) {
        int opcode = p.mem(p.ip) % 100;
        p.ip = runners[opcode](p);
    }
}
// INTCODE END

import std.container : DList;
struct Point {
    long x, y;
}

struct Nic {
    Program p;
    bool isBooting = true;
    long[3] output;
    size_t outputIndex;

    DList!Point inputQueue;
    bool inputIsX = true;
}

void part1(long[] codes) {
    Program p0;
    foreach(i, code; codes) {
        p0.memAA[i] = code;
    }

    const numComputers = 50;
    Nic[numComputers] nics;

    long expectedResult;
    bool running = true;

    foreach(i, ref n; nics) {
        n.p.id = i;
        n.isBooting = true;
        n.p.resetIntCode(p0.memAA);
        n.p.getInput = (ref pr) {
            Nic* nic = &nics[pr.id];
            if (nic.isBooting) {
                // io.writeln("Booting ", pr.id);
                nic.isBooting = false;
                return pr.id;
            }
            if (nic.inputQueue.empty) {
                // Stop running this nic to allow others to write
                nic.p.runState = RunState.Paused;
                return -1;
            }
            Point p = nic.inputQueue.back;
            long ret = (nic.inputIsX) ? p.x : p.y;
            if (!nic.inputIsX) {
                nic.inputQueue.removeBack;
                // io.writeln(pr.id, " read from queue ", p);
            }
            nic.inputIsX = !nic.inputIsX;
            // io.writeln("in returned ", ret);
            return ret;
        };
        n.p.doOutput = (ref pr, long outputCode) {
            // io.writeln(pr.id, " output ", outputCode);
            Nic* nic = &nics[pr.id];
            nic.output[nic.outputIndex++] = outputCode;
            if (nic.outputIndex == 3) {
                // Check termination
                if (nic.output[0] == 255) {
                    expectedResult = nic.output[2];
                    running = false;
                } else {
                    nics[nic.output[0].to!uint].inputQueue.insertFront( Point(nic.output[1], nic.output[2]) );
                    nic.outputIndex = 0;
                    // io.writeln("wrote ", nics[nic.output[0].to!uint].inputQueue.front);
                    // Stop running this nic to allow others to read
                    nic.p.runState = RunState.Paused;
                }
            }
        };
    }
    while(running) {
        foreach(i, ref nic; nics) {
            nic.p.runState = RunState.Running;           
            nic.p.runProgram;
        }
    }
    io.writeln(expectedResult);
}


void part2(long[] codes) {
    Program p0;
    foreach(i, code; codes) {
        p0.memAA[i] = code;
    }

    const numComputers = 50;
    Nic[numComputers] nics;

    struct Nat {
        Point input;
        bool[long] yValuesSentFromNatTo0;
    }
    Nat nat;

    long expectedResult;
    bool running = true;
    size_t round;
    size_t currentNic;

    foreach(i, ref n; nics) {
        n.p.id = i;
        n.isBooting = true;
        n.p.resetIntCode(p0.memAA);
        n.p.getInput = (ref pr) {
            Nic* nic = &nics[pr.id];
            if (nic.isBooting) {
                nic.isBooting = false;
                nic.p.runState = RunState.Paused;
                return pr.id;
            }
            if (nic.inputQueue.empty) {
                // Stop running this nic to allow others to write
                nic.p.runState = RunState.Paused;

                return -1;
            }
            Point p = nic.inputQueue.back;
            long ret = (nic.inputIsX) ? p.x : p.y;
            if (!nic.inputIsX) {
                nic.inputQueue.removeBack;
            }
            nic.inputIsX = !nic.inputIsX;
            // io.writeln("in returned ", ret);
            return ret;
        };
        n.p.doOutput = (ref pr, long outputCode) {
            Nic* nic = &nics[pr.id];
            nic.output[nic.outputIndex++] = outputCode;
            if (nic.outputIndex == 3) {
                // Check NAT
                if (nic.output[0] == 255) {
                    nat.input = Point(nic.output[1], nic.output[2]);
                    nic.outputIndex = 0;
                } else {
                    nics[nic.output[0].to!uint].inputQueue.insertFront( Point(nic.output[1], nic.output[2]) );
                    nic.outputIndex = 0;
                    // Stop running this nic to allow others to read
                    nic.p.runState = RunState.Paused;
                }
            }
        };
    }
    while(running) {
        foreach(i, ref nic; nics) {
            currentNic = i;
            nic.p.runState = RunState.Running;           
            nic.p.runProgram;
        }
        round += 1;
        // Did all other NICs stop? If so restart NIC 0 by sending the last
        // transmission we got.
        // DLANG : all() can't be called on an array, it has to be called on a range (add [])
        //         and the compile error message isn't very clear.
        if (round > 2 && nics[].all!(n => n.inputQueue.empty)) {
            if (nat.input.y in nat.yValuesSentFromNatTo0) {
                expectedResult = nat.input.y;
                running = false;
            } else {
                nat.yValuesSentFromNatTo0[nat.input.y] = true;
                nics[0].inputQueue.insertFront( Point(nat.input.x, nat.input.y) );
                nics[0].p.runState = RunState.Running;
            }
        }
    }
    io.writeln(expectedResult);
}


void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;

    part1(codes);
    part2(codes);
}