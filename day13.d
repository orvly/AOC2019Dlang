module day13;
import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

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

alias Point = Tuple!(long, "y", long, "x");

void drawBoardMode(ref Program p, ref long[Point] board) {
    Point curOutPoint;
    int outputState;
    p.doOutput = (ref p, long p_output) {
        final switch (outputState) {
        case 0:
            curOutPoint.x = p_output;
            break;
        case 1:
            curOutPoint.y = p_output;
            break;
        case 2:
            board[curOutPoint] = p_output;
            break;
        }
        outputState = (outputState + 1) % 3;
    };
    p.runProgram;
}

long runSystem1(long[] programCode) {
    Program p;
    long[Point] board;

    p.id = 0;
    foreach (i, code; programCode) {
        p.memAA[i] = code;
    }
    auto originalCode = p.memAA.dup;

    drawBoardMode(p, board);
    auto result1 = board.values.map!(code => code == 2 ? 1 : 0).sum;
    return result1;
}

void drawBoard(long[Point] board) {
    auto points = board.keys;
    auto minx = points.minElement!(p => p.x).x;
    auto maxx = points.maxElement!(p => p.x).x;
    auto miny = points.minElement!(p => p.y).y;
    auto maxy = points.maxElement!(p => p.y).y;
    foreach (y; miny .. maxy + 1) {
        foreach (x; minx .. maxx + 1) {
            final switch (board[Point(y, x)]) {
            case 0:
                io.write(' ');
                break;
            case 1:
                io.write('W');
                break;
            case 2:
                io.write('B');
                break;
            case 3:
                io.write('P');
                break;
            case 4:
                io.write('O');
                break;
            }
        }
        io.writeln();
    }
}

long runSystem2(long[] programCode) {
    Program p2;
    long[Point] board;

    p2.id = 2;
    foreach (i, code; programCode) {
        p2.memAA[i] = code;
    }
    p2.memAA[0] = 2;
    Point curOutPoint;
    int outputState;
    bool isScore = false;
    long score;
    bool drewBall = false;
    Point lastBallLoc;
    Point paddleLoc;
    int requiredMovement;

    void calcMovement(long output) {
        if (drewBall) {
            // Always moving the paddle to be closer to the ball is the only strategy required
            // for winning.
            auto ballPaddleDx = curOutPoint.x - paddleLoc.x;
            requiredMovement = (ballPaddleDx == 0) ? 0 : (ballPaddleDx / abs(ballPaddleDx));
        } else {
            drewBall = true;
        }
        lastBallLoc = curOutPoint;
    }

    p2.doOutput = (ref p, long p_output) {
        final switch (outputState) {
        case 0:
            isScore = (p_output == -1);
            if (!isScore)
                curOutPoint.x = p_output;
            break;
        case 1:
            if (!isScore)
                curOutPoint.y = p_output;
            break;
        case 2:
            if (!isScore) {
                board[curOutPoint] = p_output;
                if (p_output == 4)
                    calcMovement(p_output);
                else if (p_output == 3) {
                    paddleLoc = curOutPoint;
                }
            } else {
                score = p_output;
                // io.writeln("SCORE ", p_output);
            }
            break;
        }
        outputState = (outputState + 1) % 3;
    };
    p2.getInput = (ref p) {
        // io.writeln("INPUT requested");
        p.runState = RunState.Paused;
        return 0;
    };
    p2.runProgram;
    drawBoard(board);

    p2.getInput = (ref p) {
        // long numBlocks = board.values.count!(n => n == 2);
        // io.writeln(numBlocks);
        // drawBoard(board);
        return requiredMovement;
    };

    p2.runState = RunState.Running;
    p2.runProgram;

    return score;
}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;
    auto result = runSystem1(codes);
    io.writeln(result);
    result = runSystem2(codes);
    io.writeln(result);
}
