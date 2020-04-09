module day15;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;
import std.container: SList;

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
        // io.writeln("ADJUST by ", delta, " to ", p.relativeBase);
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

// ******** INTCODE COMPUTER END ************

alias Pnt = Tuple!(long, "x", long, "y");

Pnt[Pnt] dijkstraShortest(Pnt[][Pnt] graph, Pnt start, Pnt target) {
    Pnt[] q = graph.byKey.array; // Should be a priority queue
    bool[Pnt] qAA = q.map!(p => tuple(p, true)).assocArray;
    int[Pnt] dist;// = graph.byKey.map!(k => tuple!(k, int.max)).assocArray;
    Pnt[Pnt] prev;

    dist[start] = 0;
    while(!q.empty) {
        auto minIndx = q.minIndex!( (a, b) => dist.get(a, int.max) < dist.get(b, int.max));
        auto u = q[minIndx];
        //q.remove(minIndx);
        q = q.remove(minIndx);
        qAA.remove(u);
        if (u == target)
            break;
        foreach(neighbor; graph[u].filter!(pnt => pnt in qAA)) {
            auto alt = dist.require(u, int.max) + 1; // 1 = distance between any two nodes
            if (alt < dist.require(neighbor, int.max)) {
                dist[neighbor] = alt;
                prev[neighbor] = u;
            }
        }
    }
    return prev;
}


// Convenience wrapper for popping a value, combining .front and .removeFront
T pop(T)(SList!T list) {
    import std.range.interfaces;
    T ret = list.front;
    list.removeFront;
    return ret;
}

void main() {
    long[] codes = io.stdin.byLineCopy.array[0].split(",").map!(to!long).array;
    Program p;
    p.id=0; 
    foreach(i, code; codes) {
        p.memAA[i] = code;
    }

    // DFS:
    // For each new location we successfully move to:
    // Check each of the 4 directions whether we've already visited it
    // For each place we haven't visited and isn't a wall:
    //   Push required movement to required movements stack
    //   Push reverse movement to reverse movements stack
    //   Pop the required movements stack and return it
    //   Update our location.
    // If there aren't any unvisited locations (stuck), we must backtrack:
    //   Pop the top of the reverse movements stack and return it
    //   Update our location
    // If this is a visited location:
    //   Pop the required movement stack and return it
    //   Update our location
    // If this is a visited location and required movement is empty:
    //   Halt
    // In OUTPUT routine, read answer (result of movement).
    //   Update map with it
    //   If it's a wall then we pop the reverse movement stack, since we didn't really move.
    //   If it's not a wall, update GRAPH with a directed connection between last point and current point.
    // THEN:
    // Run Dijkstra or A* on the GRAPH to find shortest route from starting point to fuel.

    enum M {wall=0,free=1,oxygen=2,unknown}
    auto deltas= [Pnt(0,0), Pnt(0,-1), Pnt(0,1), Pnt(-1,0), Pnt(1,0)];

    Pnt add(Pnt p, int deltaind) {
        auto d=deltas[deltaind];
        return Pnt(p.x+d.x, p.y+d.y);
    }

    M[Pnt] maze;
    Pnt[][Pnt] graph;
    bool[Pnt] visited;
    Pnt loc = Pnt( 0, 0 );
    visited[loc] = true;
    Pnt oxygenLoc;
    SList!int backtrackStack;

    maze[loc] = M.free;

    p.getInput = (ref p) {
        alias NextLoc = Tuple!(int, "dir", Pnt, "loc");
        auto unvisitedLocs = iota(1, 5)
            .map!(di => NextLoc(di.to!int, add(loc, di)))
            .filter!(pNext => pNext.loc !in visited);
        bool isStuck = unvisitedLocs.empty;
        if (isStuck && backtrackStack.empty) {
            p.runState = RunState.Finished;
            return 0;
        }
        int nextDir;
        if (!isStuck) {
            auto next = unvisitedLocs.front;
            nextDir = next.dir;
            auto oppositeDir = 0;
            final switch(nextDir) {
                case 1: oppositeDir = 2; break;
                case 2: oppositeDir = 1; break;
                case 3: oppositeDir = 4; break;
                case 4: oppositeDir = 3; break;
            }
            // DLANG: Why doesn't the code below compile? Fails with "forward reference to inferred return type of function call"
            // auto oppositeDir = ((n) { final switch (n) {
            //     case 1: return 2;
            //     case 2: return 1;
            //     case 3: return 4;
            //     case 4: return 3;
            // }})(nextDir);
            backtrackStack.insertFront(oppositeDir);
            visited[next.loc] = true;
        } else {
            nextDir = backtrackStack.pop;
        }
        auto nextLoc = add(loc, nextDir);
        graph.require(loc, Pnt[].init) ~= nextLoc;

        loc = nextLoc;
        return nextDir;
    };
    p.doOutput = (ref p, long output) {
        maze[loc] = output.to!M;
        if (output == M.wall) {
            loc = add(loc, backtrackStack.pop);
            graph[loc].popBack;
        } else if (output == M.oxygen) {
            oxygenLoc = loc;
        }
    };
    p.runProgram;
    // Print the board
    auto minx = maze.keys.map!(p => p.x).minElement;
    auto maxx = maze.keys.map!(p => p.x).maxElement;
    auto miny = maze.keys.map!(p => p.y).minElement;
    auto maxy = maze.keys.map!(p => p.y).maxElement;
    // io.writeln("x=", minx, "..", maxx, ", y=", miny, "..", maxy);
    foreach(y; miny..maxy + 1) {
        foreach(x; minx..maxx + 1) {
            auto cor = Pnt(x,y);
            if (cor !in maze)
                io.write(" ");
            else {
                if (x == 0 && y == 0) 
                    io.write("R");
                else {
                    switch(maze[Pnt(x,y)]) {
                        case M.wall: io.write("#"); break;
                        case M.oxygen: io.write("X"); break;
                        default: io.write(" ");
                    }
                }
            }
        }
        io.writeln();
    }
    io.writeln("oxygen location=", oxygenLoc);
    // Part 1:
    auto shortestRoute = dijkstraShortest(graph, Pnt(0, 0), oxygenLoc);
    Pnt cur = oxygenLoc;
    Pnt start = Pnt(0, 0);
    auto len = 0;
    while(cur != start) {
        // io.writeln(cur);
        len += 1;
        cur = shortestRoute[cur];
    }
    io.writeln(len);

    // Part 2:
    // Start with oxygen location, try going in 4 directions, each NEW place we get to gets one plus.
    auto numCells = graph.length;
    int time = 0;
    bool[Pnt] cellsFilled;
    cellsFilled[oxygenLoc] = true;
    while(cellsFilled.length < numCells) {
        auto newCells = cellsFilled.byKey.map!(c => 
                graph[c].filter!(neighbor => neighbor !in cellsFilled))
            .join;
        newCells.each!(c => cellsFilled[c] = true);
        time += 1;
    }
    io.writeln(time);
}