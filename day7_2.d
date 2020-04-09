module day7_2;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

enum RunState { Running, Paused, Finished };
struct Program {
    int id;
    int[] mem;
    int ip = 0;
    RunState runState = RunState.Running;
    int delegate(ref Program me) getInput;
    void delegate(ref Program me, int output) doOutput;
}

int getValue(ref Program p, int numOperand) {
    int mode;
    if (numOperand == 1)
        mode = p.mem[p.ip] / 100 % 10;
    else if (numOperand == 2)
        mode = p.mem[p.ip] / 1000 % 10;
    else if (numOperand == 3)
        mode = p.mem[p.ip] / 10000 % 10;
    if (mode != 1 && mode != 0)
        throw new Exception("Error in mode");
    return (mode == 1) ? p.mem[p.ip + numOperand] : p.mem[p.mem[p.ip + numOperand]];
}

alias Runner = int function(ref Program);
immutable Runner[int] runners;

shared static this() {
    import std.exception: assumeUnique;
    Runner[int] temp;
    temp[1] = (ref Program p) { 
        p.mem[p.mem[p.ip + 3]] = getValue(p, 1) + getValue(p, 2);
        return p.ip + 4;
    };
    temp[2] = (ref Program p) { 
        p.mem[p.mem[p.ip + 3]] = getValue(p, 1) * getValue(p, 2);
        return p.ip + 4;
    };
    temp[3] = (ref Program p) {
        int input = p.getInput(p);
        p.mem[p.mem[p.ip + 1]] = input;
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
        p.mem[p.mem[p.ip + 3]] = (getValue(p, 1) < getValue(p,2)) ? 1 : 0;
        return p.ip + 4;
    };
    temp[8] = (ref Program p) {
        p.mem[p.mem[p.ip + 3]] = (getValue(p, 1) == getValue(p,2 )) ? 1 : 0;
        return p.ip + 4;
    };
    temp[99] = (ref Program p) {
        p.runState = RunState.Finished;
        return p.ip;
    }; 
    
    runners = assumeUnique(temp);
}

void runProgram(ref Program p) {
    while(p.runState == RunState.Running) {
        int opcode = p.mem[p.ip] % 100;
        p.ip = runners[opcode](p);
    }
}

int runSystem_2(int[] programCode, int[] initialInputs) {
    const numPrograms = initialInputs.length;
    auto programs = new Program[numPrograms];
    auto givenInitial = new bool[numPrograms];
    int inOutChannel = 0;
    foreach(i, ref p; programs) {
        // Initialize program p
        p.id = i.to!int;
        p.mem = programCode.dup;
        // Initialize the program's input/output callbacks to read/write through the "channel"
        // which is really a simple integer, since we run them all sequentially anyway..,
        p.getInput = (ref p) { 
            if (givenInitial[p.id]) 
                return inOutChannel; 
            else {
                givenInitial[p.id] = true;
                return initialInputs[p.id];
            }
        };
        p.doOutput = (ref p, output) { 
            inOutChannel = output; 
            // Pause this program after outputting, so the next one could pick it up as input and continue
            p.runState = RunState.Paused; 
        };
    }
    // Main runner
    foreach(ref p; programs.cycle) {
      p.runState = RunState.Running;
      p.runProgram;
      if (p.runState == RunState.Finished)
          break;
      }
    return inOutChannel;
}

void main() {
    int[] a = io.stdin.byLineCopy.array[0].split(",").map!(to!int).array;
    
    int[] inputs = iota(5, 10).array;
    int[] allOutputs;
    do {
        allOutputs ~= runSystem_2(a, inputs);
    } while (inputs.nextPermutation);
    io.writeln(allOutputs.maxElement);
}
