module day9;
import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

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
    switch(mode) {
        case 0: return p.mem(p.mem(p.ip + numOperand));
        case 1: return p.mem(p.ip + numOperand);
        case 2: return p.mem(p.mem(p.ip + numOperand) + p.relativeBase);
        default: throw new Exception("Error in mode: " ~ mode.to!string);
    }
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
        p.getLValue(3) = (getValue(p, 1) < getValue(p,2)) ? 1 : 0;
        return p.ip + 4;
    };
    temp[8] = (ref Program p) {
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

long runSystem_1(long[] programCode, int input) {
    Program p;
    p.id = 0;
    foreach(i, code; programCode)
        p.memAA[i] = code;
    long output;
    p.getInput = (ref p) => input;
    p.doOutput = (ref p, long p_output) { output = p_output; };
    p.runProgram;
    return output;
}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;
    auto result1 = runSystem_1(codes, 1);
    io.writeln(result1);
    auto result2 = runSystem_1(codes, 2);
    io.writeln(result2);
}
