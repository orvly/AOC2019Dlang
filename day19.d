module day19;

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
    pr.memAA = memory.dup;
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
        // io.writeln("op:", opcode);
        p.ip = runners[opcode](p);
    }
}
// INTCODE END

alias Pnt = Tuple!(long, "x", long, "y");
auto deltas= [Pnt(0,-1), Pnt(0,1), Pnt(-1,0), Pnt(1,0)];

Pnt add(Pnt p, int deltaind) {
    auto d=deltas[deltaind];
    return Pnt(p.x+d.x, p.y+d.y);
}

bool getPointContent(ref Program pr, long[long] prBackup, Pnt p) {
    pr.resetIntCode(prBackup);
    bool answer;
    int coorsInd = 0;
    pr.getInput = (ref pr) {
        if (coorsInd++ == 0) {
            return p.x;
        }
        coorsInd = 0;
        return p.y;
    };
    pr.doOutput = (ref pr, long output) {
        answer = (output == 1);
    };
    pr.runProgram;
    return answer;
}

void part1(long[] codes) {
    Program pr;

    pr.id=0; 
    foreach(i, code; codes)
        pr.memAA[i] = code;
    auto memBack = pr.memAA.dup;

    bool[Pnt] map;
    foreach(x; 0..50) {
        foreach(y; 0..50) {
            Pnt p = Pnt(x, y);
            if (getPointContent(pr, memBack, p)) {
                map[p] = true;
            }
        }
    }
    io.writeln(map.length);

    // foreach(y; 0..80) {
    //     foreach(x; 0..80) {
    //         io.write(map.get(Pnt(x,y), false) ? '#' : '.');
    //     }
    //     io.writeln();
    // }
}

void part2(long[] codes) {
    Program pr;

    import std.datetime.stopwatch : StopWatch, AutoStart;
    auto sw = StopWatch(AutoStart.yes);

    pr.id=0; 
    foreach(i, code; codes)
        pr.memAA[i] = code;
    auto memBack = pr.memAA.dup;

    // Calculate angles of rays by intersecting them with an horizontal line
    const y = 1000; // A large enough y to find angles with enough precision
    int x = 0;
    int[2] xIntersects;
    int intersectsFound = 0;
    bool last = false;
    while(intersectsFound < 2) {
        if (getPointContent(pr, memBack, Pnt(x, y)) != last) {
            xIntersects[intersectsFound++] = x;
            last = !last;
        }
        x += 1;
    }
    // The 2nd point was recorded when "last" changed so it's an empty square, go back one
    xIntersects[1] -= 1; 
    // io.writeln(xIntersects);
    const alpha3 = atan(xIntersects[0].to!double / y);
    const alpha2 = atan(y.to!double / xIntersects[1]);
    const alpha1 = PI / 2 - (alpha2 + alpha3);

    // io.writeln(alpha3 * 180 / PI, ' ', alpha2 * 180 / PI, ' ', alpha1 * 180 / PI);

    const d = 100; // Size of Santa's ship
    Pnt result;
    foreach(ey; 100..10000) {
        double ex_f = ey * tan(alpha1 + alpha3);
        // 0.1 is a correction which needed to be done to fx, I'm not sure why.
        double fx_f = ey * tan(alpha3) + 0.1; 
        auto ex = lrint(ex_f);
        auto fx = lrint(fx_f);

        if (ex - d < fx) 
            continue;

        // // DEBUGGING
        // io.writeln("Trying: ey=", ey, ", x range=", fx, "...", ex);
        // bool t = false;
        // long[2] eps = [fx, ex];
        // int epsI;
        // foreach(testx; fx-10..ex+20) {
        //     if (getPointContent(pr, memBack, Pnt(testx, ey)) != t) {
        //         io.write(testx, "..");
        //         eps[epsI] = abs(eps[epsI] - testx);
        //         epsI++;
        //         t = !t;
        //     }
        // }
        // eps[1] -= 1;
        // io.write(", eps = ", eps);
        // io.writeln();

        // Adjust for epsilon errors against actual points horizontally
        if (!getPointContent(pr, memBack, Pnt(ex, ey)) || !getPointContent(pr, memBack, Pnt(fx, ey))) {
            continue;
        }
        if (getPointContent(pr, memBack, Pnt(ex + 1, ey))) {
            ex += 1;
        }
        if (getPointContent(pr, memBack, Pnt(fx - 1, ey))) {
            fx -= 1;
        }

        auto px = ex - d + 1;
        // Check that we fit inside dy
        if (getPointContent(pr, memBack, Pnt(px, ey + d - 1))) {
            result = Pnt(px, ey);
            break;
        }
    }
    sw.stop;
    // io.writeln(result);
    io.writeln(result.x * 10000 + result.y);

    // io.writeln("time: ", sw.peek.total!"msecs");
}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;

    part1(codes);
    part2(codes);
}
