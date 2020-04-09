module day17;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

// ******** INTCODE COMPUTER ************

enum RunState {
    Running,
    Paused,
    Finished
};
struct Program {
    int id;
    long[long] memAA;
    long ip = 0;
    long relativeBase;
    RunState runState = RunState.Running;
    long delegate(ref Program me) getInput;
    void delegate(ref Program me, long output) doOutput;
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
    switch (mode) {
    case 0:
        return p.mem(p.mem(p.ip + numOperand));
    case 2:
        return p.mem(p.mem(p.ip + numOperand) + p.relativeBase);
    default:
        throw new Exception("Error in mode: " ~ mode.to!string);
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
    switch (mode) {
    case 0:
        return p.mem(p.mem(p.ip + numOperand));
    case 1:
        return p.mem(p.ip + numOperand);
    case 2:
        return p.mem(p.mem(p.ip + numOperand) + p.relativeBase);
    default:
        throw new Exception("Error in mode: " ~ mode.to!string);
    }
    // return (mode == 1) ? p.mem(p.ip + numOperand) : p.mem(p.mem(p.ip + numOperand));
}

alias Runner = long function(ref Program);
immutable Runner[int] runners;

shared static this() {
    import std.exception : assumeUnique;

    Runner[int] temp;
    temp[1] = (ref Program p) {
        // p.mem(p.mem(p.ip + 3)) = getValue(p, 1) + getValue(p, 2);
        p.getLValue(3) = p.getValue(1) + p.getValue(2);
        return p.ip + 4;
    };
    temp[2] = (ref Program p) {
        // p.mem(p.mem(p.ip + 3)) = getValue(p, 1) * getValue(p, 2);
        p.getLValue(3) = p.getValue(1) * p.getValue(2);
        return p.ip + 4;
    };
    temp[3] = (ref Program p) {
        auto input = p.getInput(p);
        p.getLValue(1) = input;
        // p.mem(p.mem(p.ip + 1)) = input;
        // io.writeln("INPUT: ", input, " in address ", p.mem(p.ip + 1), " full code=", p.mem(p.ip), " ", p.mem(p.ip+1));
        return p.ip + 2;
    };
    temp[4] = (ref Program p) {
        // io.writeln("OUT:", getValue(p, 1));
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
        p.getLValue(3) = (getValue(p, 1) < getValue(p, 2)) ? 1 : 0;
        return p.ip + 4;
    };
    temp[8] = (ref Program p) {
        // p.mem(p.mem(p.ip + 3)) = (getValue(p, 1) == getValue(p,2 )) ? 1 : 0;
        p.getLValue(3) = (getValue(p, 1) == getValue(p, 2)) ? 1 : 0;
        return p.ip + 4;
    };
    temp[9] = (ref Program p) {
        long delta = getValue(p, 1);
        p.relativeBase += getValue(p, 1);
        // io.writeln("ADJUST by ", delta, " to ", p.relativeBase);
        return p.ip + 2;
    };
    temp[99] = (ref Program p) { p.runState = RunState.Finished; return p.ip; };

    runners = assumeUnique(temp);
}

void runProgram(ref Program p) {
    while (p.runState == RunState.Running) {
        int opcode = p.mem(p.ip) % 100;
        // io.writeln("op:", opcode);
        p.ip = runners[opcode](p);
    }
}
// ******** INTCODE COMPUTER END ************

void part1(long[] codes) {
    Program pr;
    enum M {
        wall = 35,
        free = 46,
        robup = '^',
        robdown = 'v',
        robleft = '<',
        robright = '>'
    }

    alias Pnt = Tuple!(long, "x", long, "y");
    auto deltas = [Pnt(0, -1), Pnt(0, 1), Pnt(-1, 0), Pnt(1, 0)];
    Pnt add(Pnt p, int deltaind) {
        auto d = deltas[deltaind];
        return Pnt(p.x + d.x, p.y + d.y);
    }

    byte[Pnt] map;

    pr.id = 0;
    foreach (i, code; codes)
        pr.memAA[i] = code;

    pr.getInput = (ref pr) { return 0; };
    Pnt p;
    pr.doOutput = (ref pr, long output) {
        if (output == 10) {
            p.y++;
            p.x = 0;
        } else {
            map[p] = output.to!byte;
            p.x++;
        }
    };
    pr.runProgram;
    auto minx = map.keys.minElement!(p => p.x).x;
    auto miny = map.keys.minElement!(p => p.y).y;
    auto maxx = map.keys.maxElement!(p => p.x).x;
    auto maxy = map.keys.maxElement!(p => p.y).y;
    long sum;
    foreach (y; miny .. maxy + 1) {
        foreach (x; minx .. maxx + 1) {
            Pnt p1 = Pnt(x, y);

            if (map.require(p1, M.free) == M.wall) {
                bool isInter = true;
                foreach (i; 0 .. deltas.length) {
                    if (map.require(add(p1, i.to!int), M.free) != M.wall) {
                        isInter = false;
                        break;
                    }
                }
                if (isInter) {
                    sum += p1.x * p1.y;
                }
            } //if wall
        } // for
    } // for
    io.writeln(sum);

    // Print map as a preparation for part 2
    foreach (y; miny .. maxy + 1) {
        foreach (x; minx .. maxx + 1) {
            Pnt p1 = Pnt(x, y);
            final switch (map.require(p1, M.free)) {
            case M.wall:
                io.write("#");
                break;
            case M.free:
                io.write(".");
                break;
            case M.robup:
                io.write("^");
                break;
            case M.robdown:
                io.write("V");
                break;
            case M.robleft:
                io.write("<");
                break;
            case M.robright:
                io.write(">");
                break;
            }
        }
        io.writeln;
    }

}

void part2(long[] codes) {
    Program pr;
    enum M {
        wall = 35,
        free = 46,
        robup = '^',
        robdown = 'v',
        robleft = '<',
        robright = '>'
    }

    alias Pnt = Tuple!(long, "x", long, "y");
    auto deltas = [Pnt(0, -1), Pnt(0, 1), Pnt(-1, 0), Pnt(1, 0)];
    Pnt add(Pnt p, int deltaind) {
        auto d = deltas[deltaind];
        return Pnt(p.x + d.x, p.y + d.y);
    }

    byte[Pnt] map;

    pr.id = 0;
    foreach (i, code; codes)
        pr.memAA[i] = code;

    int inputState = 0;
    int curInputIndex = 0;

    // Breakdown of route to the 3 functions.
    // ======================================
    // NOTE: I arrived at these results by manually by writing the route
    // and trying to break it down. No other tricky algorithm was used.
    // The rough draft is in the file day17_output_path.txt

    string mainRoutine = "A,B,A,B,A,C,B,C,A,C";
    string funcA = "L,6,R,12,L,6";
    string funcB = "R,12,L,10,L,4,L,6";
    string funcC = "L,10,L,10,L,4,L,6";
    string answer = "n";

    pr.getInput = (ref pr) {
        long inp;
        string myOutput;
        switch (inputState) {
        case 0:
            myOutput = mainRoutine;
            break;
        case 1:
            myOutput = funcA;
            break;
        case 2:
            myOutput = funcB;
            break;
        case 3:
            myOutput = funcC;
            break;
        case 4:
            myOutput = answer;
            break;
        default:
            throw new Exception("Unexpected input requested");
        }
        if (curInputIndex == myOutput.length) {
            inputState += 1;
            curInputIndex = 0;
            inp = 10;
        } else {
            inp = myOutput[curInputIndex++].to!long;
        }
        // io.writeln("Input: ", inp);
        return inp;
    };
    Pnt p;
    pr.doOutput = (ref pr, long output) {
        if (output > 256) {
            io.writeln("DUST = ", output);
        } else if (output == 10) {
            p.y++;
            p.x = 0;
        } else {
            map[p] = output.to!byte;
            p.x++;
        }
    };
    pr.memAA[0] = 2;
    pr.runProgram;

}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;

    part1(codes);
    part2(codes);
}
