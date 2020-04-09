module day25;

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

void part1(long[] codes, bool interactiveMode) {
    Program p0;
    foreach(i, code; codes) {
        p0.memAA[i] = code;
    }
    auto codeBackup = p0.memAA.dup;
    string output;
    string input = "";
    int curInputIndex;
    RobotState robotState;
    robotState.traverseState = TraverseState.Collecting;
    bool finished = false;

    p0.id = 0;
    p0.getInput = (ref pr) {
        import std.string;
        if (interactiveMode) {
            io.writeln(output);
            io.stdout.flush; //DLANG: Why do we have to flush here before calling to readln?
        }
        if (input == "") {
            if (interactiveMode) {
                input = io.readln;
                input = input.chomp;
            } else {
                input = analyzeLocation(output, robotState);
                if (input == quitCommand) {
                    finished = true;
                    p0.runState = RunState.Finished;
                }
            }
            curInputIndex = 0;
        }
        output = "";
        long inpCharCode;
        if (curInputIndex == input.length) {
            curInputIndex = 0;
            inpCharCode = 10;
        } else {
            inpCharCode = input[curInputIndex++].to!long;
        }
        return inpCharCode;
    };
    p0.doOutput = (ref pr, long outputCode) {
        input = "";
        output ~= outputCode.to!dchar;
    };

    p0.runState = RunState.Running;
    p0.runProgram;
    io.writeln(output);
}

/*
   PARTIAL MAP made while playing:

    Passages
  spool of cat6
      |
   Corridor
  infinite loop
      |
    Hallway     -     Engineering
    wreath            fixed point
      |
    Sick Bay    -     Hull Breach  -    Gift Wrapping Center   -    Kitchen
                                            Sand                  molten lava
      |
    Arcade      -   Warp Drive Maint.  -     Navigation      -    Storage
giant electromagnet   escape pod                               space law space brochure
      |                  |                       |                   |
   Holodeck            Stables         Hot Chocolate Fountain    Science Lab 
   candy cane                                photons              fuel cell
                                                                    |
                                     Pressure-Sensitive Floor -   Security Checkpoint
                                                                  "Too light"


*/
enum TraverseState {
    Collecting,
    PickingUp,
    GoingToCheckpoint,
    Combining,
    TryingToEnter,
    Success,
}
enum Direction {
     north, south, east, west, none,
}

Direction getOpposite(Direction d) {
    final switch(d) {
        case Direction.east: return Direction.west;
        case Direction.west: return Direction.east;
        case Direction.north: return Direction.south;
        case Direction.south: return Direction.north;
        case Direction.none: throw new Exception("Illegal direction");
    }
}

struct Stack(T) {
    T[] stack;
    
    void pushMany(R)(R items) if (isInputRange!R) {
        foreach(item; items) {
            stack ~= item;
        }
    }
    void push(T item) {
        stack ~= item;
    }
    T peek() {
        return stack.back;
    }
    T pop() {
        T temp = stack.back;
        stack.popBack;
        return temp;
    }
    bool empty() {
        return stack.length == 0;
    }

    Stack!T dupAndMap(T function(T) mapper) {
        return Stack!T( stack.map!(mapper).array );
    }

    void reverse() {
        stack.reverse;
    }
    void clear() {
        stack = null;
    }
}

struct RobotState {
    TraverseState traverseState;
    Stack!Direction dfsStack;
    Stack!Direction reverseStack;
    Stack!string currentPickedItems;
    string[] items;

    Stack!Direction pathToEndRoom;
    Direction exitFromEndRoom;

    bool[string] knownRooms;

    ulong curItemsHeldBits;
    ulong curItemsToHoldBits;
    ulong[] knownTooHeavyItems;
}

immutable string[] forbiddenItems = [ 
    "photons",
    "giant electromagnet",
    "molten lava",
    "infinite loop",
    "escape pod",
];
immutable string quitCommand = "quit";

struct ParseResults {
    Direction[] directions;
    string[] items;
}

ParseResults parseLines(string description) {
    import std.string, std.traits, std.exception;
    ParseResults results;
    // DLANG: I tried using the chunkBy function on the results of splitLines, inside a lambda, but got a compilation
    // error:  "function chunkBy cannot access frame of function "parseLines".  Not sure why. 
    auto dashedLines = description.splitLines
        .filter!(line => line.startsWith("- ")) 
        .map!(line => line.strip("- "));
    foreach(string line; dashedLines) {
        auto dir = line.to!Direction.ifThrown(Direction.none);
        if (dir != Direction.none) {
            results.directions ~= dir;
        } else {
            results.items ~= line;
        }
    }
    return results;
}

bool tryParse(string dashedLine) {
    import std.exception;
    // DLANG: Why removing the parens from around the first part causes the compilation error:
    //  "template identifier `to` is not a member of variable dashedLine"
    return (dashedLine.to!Direction.ifThrown(Direction.none)) != Direction.none;
}

// Returns the next action to take
// "quit" is a special command telling us to quit
string analyzeLocation(string description, ref RobotState state) {
/*
    Forbidden items:
    photons
    giant electromagnet
    molten lava
    infinite loop
    escape pod

    Termination condition:
    When going west from "Security Checkpoint", DON'T get "Alert!" in output, and DON'T quit running
    NOTE: Following combination ends the game when going past the checkpoint, for some reason...
    fixed point (??)
    wreath
    sand
    space law space brochure
OUTPUT FORMAT:
== Warp Drive Maintenance ==
It appears to be working normally.

Doors here lead:
- east
- south
- west

Items here:
- escape pod

Command?

*/

    import std.string;
    immutable endLocation = "Security Checkpoint";

    Direction nextDirection = Direction.none;
    string nextCommand = null;
    if (state.traverseState == TraverseState.Collecting) {
        // DLANG: It wasn't obvious what to do with the result of spliter(). It can be wrapped
        // in an InputRange but you can't access it with indices and I want to take the second one. 
        // The most obvious thing would be to create a ForwardRange but it's not obvious how to do it.
        auto roomNameRaw = description.splitter("==").array;
        string roomName = (roomNameRaw.length > 1) ? roomNameRaw[1].strip : null;
        if ( roomName !is null && (roomName in state.knownRooms) is null) {
            io.writeln(roomName);
            // Parse lines beginning with a dash from the description. They could be either directions or items,
            // parseLines() collects them into results.directions and results.items.
            ParseResults results = description.parseLines;
            io.writeln(results.directions);
            io.writeln(results.items);
            state.knownRooms[roomName] = true;
            // Direction.none is used as a marker to signify we're finished with exits for this room,
            // and we can go back. If later we pop it from the stack we know we're finished with this room.
            state.dfsStack.push(Direction.none); 
            if (roomName != endLocation) {
                // Push all directions, not including the one we entered from, into the directions stack.
                auto wayWeEntered = state.reverseStack.empty() ? Direction.none : state.reverseStack.peek();
                state.dfsStack.pushMany(results.directions.filter!(d => d != wayWeEntered));
            } else {
                // This is the end location, but we may not be done yet collection all items.
                // Remember the path we have travelled here so we can come back here when we're finished with
                // the DFS walk and we end back where we started.
                // We ignore the exits from it, because, to simplify things, this assumes the end location 
                // doesn't have any exits to the rest of the maze except into the "test" room (Pressure Sensitive Floor) 
                // and back into where we came from.
                state.pathToEndRoom = state.reverseStack.dupAndMap(d => d.getOpposite);
                state.pathToEndRoom.reverse;
                // Assumption: the way out to the testing pad is the exit which is not the way we came in.
                state.exitFromEndRoom = results.directions.filter!(d => d != state.reverseStack.peek()).front;
            }
            if (results.items.length > 0) {
                auto legalItems = results.items.filter!(item => !forbiddenItems.canFind(item));
                // DLANG: Why doesn't appender() fail to compile when its argument is used without &  ?
                // I think it silently creates a copy of its parameter and then discards it.
                appender(&state.items) ~= legalItems;
                state.currentPickedItems.pushMany(legalItems);
                if (!state.currentPickedItems.empty) {
                    state.traverseState = TraverseState.PickingUp;
                    // Call just once to ourselves to return the first action for the new state.
                    return analyzeLocation(description, state);
                }
            }
        }
        nextDirection = state.dfsStack.pop;
        if (!state.dfsStack.empty) {
            io.writeln("next dir=", nextDirection);
            if (nextDirection == Direction.none) {
                nextDirection = state.reverseStack.pop;
            } else {
                state.reverseStack.push(nextDirection.getOpposite);
            }
        } else {
            // We have finished exploring the maze and collecting all items, go to the checkpoint
            state.traverseState = TraverseState.GoingToCheckpoint;
            // io.writeln(state.pathToEndRoom.peek);
            // Call just once to ourselves to return the first action for the new state.
            return analyzeLocation(description, state);
        }
    }
    else if (state.traverseState == TraverseState.PickingUp) {
        if (state.currentPickedItems.empty) {
            state.traverseState = TraverseState.Collecting;
            // Call just once to ourselves to return the first action for the new state.
            return analyzeLocation(description, state);
        } else {
            nextCommand = "take " ~ state.currentPickedItems.pop;
        }
    }
    else if (state.traverseState == TraverseState.GoingToCheckpoint) {
        auto roomNameRaw = description.splitter("==").array;
        string roomName = (roomNameRaw.length > 1) ? roomNameRaw[1].strip : null;
        io.writeln(roomName);

        if (!state.pathToEndRoom.empty) {
            nextDirection = state.pathToEndRoom.pop;
        } else {
            io.writeln(state.items);
            state.traverseState = TraverseState.Combining;
            // We start by holding all items, and testing the first one.
            state.curItemsHeldBits = (1 << state.items.length) - 1;
            state.curItemsToHoldBits = 1;
            // TESTING:
            // nextCommand = quitCommand;

            // Call just once to ourselves to return the first action for the new state.
            return analyzeLocation(description, state);
        }
    }
    else if (state.traverseState == TraverseState.Combining) {
        // io.writeln(format("curItemsToHoldBits = %x, curItemsHeldBits = %x", state.curItemsToHoldBits, state.curItemsHeldBits));
        if (state.curItemsHeldBits != state.curItemsToHoldBits) {
            // We're not at the desired state, find the next item to drop / take to make us 
            // be at the desired state.
            ulong mask = 1;
            size_t numItem;
            while(numItem < state.items.length) {
                if ( (state.curItemsHeldBits & mask) != (state.curItemsToHoldBits & mask) ) {
                    if ( (state.curItemsHeldBits & mask) != 0) {
                        nextCommand = "drop " ~ state.items[numItem];
                        state.curItemsHeldBits &= ~mask;
                    } else {
                        nextCommand = "take " ~ state.items[numItem];
                        state.curItemsHeldBits |= mask;
                    }
                    break;
                }
                mask <<= 1;
                numItem += 1;
            } // while
        } else {
            // If state.curItemsHeldBits == state.curItemsToHoldBits then we're at the desired
            // state, try going into the test room and see if we made it.
            io.writeln("Trying to enter...");
            state.traverseState = TraverseState.TryingToEnter;
            nextDirection = state.exitFromEndRoom;
        }
    }
    else if (state.traverseState == TraverseState.TryingToEnter) {
        // Check if we were ejected from the testing room back.
        // If not then find out the password and print it.
        // If we were, try to find out if we were too light or too heavy.
        // If too heavy, remember this bit combination.
        // Then find next bit combination which include none of the "too heavy" bit combinations.
        // Also deal with the case that some combinations seem to make the game halt, and so
        // it should be restarted.
        // Description in case of rejection:
        /*
            == Pressure-Sensitive Floor ==
            Analyzing...
            Doors here lead:
            - east
            A loud, robotic voice says "Alert! Droids on this ship are lighter than the detected value!" and you are ejected back to the checkpoint.
            == Security Checkpoint ==        
            // ...
        */
        if (description.canFind("lighter")) {
            // TODO: Uncomment this line!!!
            state.knownTooHeavyItems ~= state.curItemsHeldBits;
        }
        if (description.canFind(endLocation)) {
            const ulong maxCombo = (1 << state.items.length) - 1;
            // Search for the next combination of bits (starting with curItemsHeldBits+1) that doesn't 
            // contain known heavy combinations of items.
            bool found = false;
            foreach(ulong combo; (state.curItemsHeldBits + 1)..(maxCombo + 1)) {
                // 110111 & 000011 == 000011
                // 110101 & 000011 != 000011
                if (state.knownTooHeavyItems.all!(known => (combo & known) != known)) {
                    state.curItemsToHoldBits = combo;
                    found = true;
                    io.writeln(format("Trying item combination %x", state.curItemsToHoldBits));
                    break;
                }
            }
            if (!found) {
                io.writeln("FAILED to find a suitable combination");
                nextCommand = quitCommand;
            } else {
                state.traverseState = TraverseState.Combining;
                return analyzeLocation(description, state);
            }
        } else {
            io.writeln("Made it past checkpoint");
            io.writeln(description);
            nextCommand = quitCommand;
        }
    }
    if (nextCommand != null) {
        io.writeln("-> ", nextCommand);
        return nextCommand;
    }
    io.writeln("-> ", nextDirection);
    if (nextDirection == Direction.none) {
        throw new Exception("Illegal direction");
    }
    return nextDirection.to!string;
}

void main() {
    // long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;
    auto f = io.File("day25_input.txt", "r");
    long[] codes = f.byLineCopy.array[0].split(",").map!(to!long).array;

    // NOTE: Call with true to run the game interactively!
    part1(codes, false);
}