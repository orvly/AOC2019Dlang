module day21;

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


enum CommandType {
    WALK, RUN, AND, OR, NOT,
}
enum Register {
     None, T, J, A, B, C, D, E, F, G, H, I
}

struct Command {
    CommandType type;
    Register reg1;
    Register reg2;
}

string runCommands(ref Program pr, long[long] prBackup, Command[] commands) {
    import std.format;

    enum State {
        NewCommand,
        InCommand,
        EndCommand,
    }
    int curCommandInd;
    string curCommandString;
    int curCommandIndInString;
    State state = State.NewCommand;
    string output;

    pr.resetIntCode(prBackup);
    pr.getInput = (ref pr) {
        long outChar;
        final switch(state) {
            case State.NewCommand:
                curCommandString = format!"%s %s %s"(
                    commands[curCommandInd].type.to!string, 
                    commands[curCommandInd].reg1 == Register.None ? "" : commands[curCommandInd].reg1.to!string,
                    commands[curCommandInd].reg2 == Register.None ? "" : commands[curCommandInd].reg2.to!string);
                outChar = curCommandString[0].to!long;
                curCommandIndInString = 1;
                state = State.InCommand;
                break;
            case State.InCommand:
                outChar = curCommandString[curCommandIndInString].to!long;
                if (++curCommandIndInString == curCommandString.length) {
                    state = State.EndCommand;
                }
                break;
            case State.EndCommand:
                outChar = 10;
                curCommandInd += 1;
                state = State.NewCommand;
                break;
        }
        debug(1) { io.write(outChar.to!char); }
        return outChar;
    };
    pr.doOutput = (ref pr, long outputCode) {
        if (outputCode > 'z'.to!long) {
            output = outputCode.to!string;
        }
        else {
            output ~= outputCode.to!char;
        }
    };
    pr.runProgram;

    return output;
}

void part1(long[] codes) {
    Program pr;

    pr.id=0; 
    foreach(i, code; codes)
        pr.memAA[i] = code;
    auto memBack = pr.memAA.dup;
/*

NOT A J  -- If A !ground then jump
NOT B T  -- If B !ground then temp = jump
AND T J  -- If temp(jump over B) AND J (jump over A) => temp = Jump, else don't
NOT C T  -- If C !ground, then jump
AND T J  -- If temp (jump over A+B) AND J (jump over C) ==> Temp = Jump, else don't
AND D J  -- If temp=JUMP and D is Ground => Jump.  Else don't.

NOT D J -- If D !ground then jump -> We'll always fall since a jump is 4 squares, apparently.

We need: If ANY of A, B, C is hole (false) then jump.
Don't jump if D is hole, since we'll fall into it.

NOT A J
NOT B T
OR  T J 
NOT C T 
OR  T J
AND D J
*/
    Command[] commands = [
        Command ( CommandType.NOT, Register.A, Register.J ),
        Command ( CommandType.NOT, Register.B, Register.T ),
        Command ( CommandType.OR,  Register.T, Register.J ),
        Command ( CommandType.NOT, Register.C, Register.T ),
        Command ( CommandType.OR,  Register.T, Register.J ),
        Command ( CommandType.AND, Register.D, Register.J ),

        Command ( CommandType.WALK, Register.None, Register.None ), 
    ];
    string output = runCommands(pr, memBack, commands);
    io.writeln(output);
}


void part2(long[] codes) {
    Program pr;

    pr.id=0; 
    foreach(i, code; codes)
        pr.memAA[i] = code;
    auto memBack = pr.memAA.dup;
/*

Assume question is fair and there's a solution to every set of ground we meet.
So if we see a hole in I then assume there's ground behind it??

If E..I is ground -> same logic as before.
If not:  we should cross this with 2 jumps, we don't want to jump immediately.
First jump should bring us to a place where we could make the second jump safely.

XABCDEFGHI
@---------
###.#.#...#####

If we do jump NOW, we land at a place where we can't go forward AND we can't jump.
That is, both E and H are holes.
In this case, don't jump, go on forward and hope that we'll get a situation where we CAN jump.
E==hole && H==hole 
<=>  (de morgan)
NOT(E==ground || H==ground)
If we get 1 here then we should NOT jump, so we should reverse that so we would get 0,
and then AND that with the result of part 1:
E==1 || h==1

Let's call result of this second check R:
R = (E || H)

How to calculate R using only T (assume T starts with FALSE, see below how to achieve this):
OR  E T
OR  H T

Code for part 1 did OR : !A|!B|!C|D  
Let's call part 1 K:
K = (!A|!B|!C|D)

R=false, K=true => false
R=false, K=false => false
R=true,  K=true  => true
R=true,  K=false => false

So we need:
R = R AND K
So final line should be:
AND T J

BUT we need to zero T after ending part 1 and before starting part 2.
To do that we can build a XOR out of AND and NOT, without changing J.
T = J AND !J
NOT J T
AND J T
J=true: T=false
J=false: T=false

SO:
NOT A J  -- Same as part 1
NOT B T
OR  T J 
NOT C T 
OR  T J
AND D J  -- Result of abcd is in J (called K above). Now we cannot touch J until the end.

NOT J T  -- Reset T
AND J T

OR  E T  
OR  I T  -- Now T contains R above (result of part 2)
AND T J  -- Now If T==FALSE then J should be FALSE.

*/
    Command[] commands = [

        Command ( CommandType.NOT, Register.A, Register.J ),
        Command ( CommandType.NOT, Register.B, Register.T ),
        Command ( CommandType.OR,  Register.T, Register.J ),
        Command ( CommandType.NOT, Register.C, Register.T ),
        Command ( CommandType.OR,  Register.T, Register.J ),
        Command ( CommandType.AND, Register.D, Register.J ),

        Command ( CommandType.NOT, Register.J, Register.T ),
        Command ( CommandType.AND, Register.J, Register.T ),

        Command ( CommandType.OR,  Register.E, Register.T ),
        Command ( CommandType.OR,  Register.H, Register.T ),
        Command ( CommandType.AND, Register.T, Register.J ),

        Command ( CommandType.RUN, Register.None, Register.None ), 
    ];
    string output = runCommands(pr, memBack, commands);
    io.writeln(output);
}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;

    part1(codes);
    part2(codes);
}