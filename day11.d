module day11;

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
alias Point = Tuple!(int, "y", int, "x");
long paint(long[] programCode, int startColor) {
    int[Point] hull;
    Point[] deltas = [Point(-1, 0), Point(0, 1), Point(1, 0), Point(0, -1)];
    int dir = 0;
    Point pos;
    Program p;
    p.id = 0;
    int outputNum;
    bool[Point] paintedOnce;
    hull[pos] = startColor;

    foreach (i, code; programCode)
        p.memAA[i] = code;

    p.getInput = (ref p) => hull.require(pos, 0);
    p.doOutput = (ref p, long p_output) {
        if (outputNum == 0) {
            hull[pos] = p_output.to!int;
            paintedOnce.require(pos);
        } else {
            int turn = (p_output == 0) ? -1 : 1;
            dir = (dir + turn + 4) % 4;
            auto delta = deltas[dir];
            pos.x += delta.x;
            pos.y += delta.y;
        }
        outputNum = (outputNum + 1) % 2;
    };
    p.runProgram;
    auto result1 = paintedOnce.keys.length;
    if (startColor == 1) {
        int miny = hull.keys.minElement!(p => p.y).y;
        int minx = hull.keys.minElement!(p => p.x).x;
        int maxy = hull.keys.maxElement!(p => p.x).x;
        int maxx = hull.keys.maxElement!(p => p.x).x;
        foreach (y; miny .. maxy + 1) {
            foreach (x; minx .. maxx + 1) {
                io.write(hull.require(Point(y, x), 0) == 1 ? 'X' : ' ');
            }
            io.writeln();
        }
    }
    return result1;
}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;
    auto result1 = paint(codes, 0);
    io.writeln(result1);
    paint(codes, 1);
}
