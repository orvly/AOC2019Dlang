module day18_1;
import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;
import std.algorithm.comparison : min;

alias Pnt = Tuple!(long, "x", long, "y");

string toStr(Pnt p) {
    import std.format;
    return format("(%s,%s)", p.x, p.y);
}

bool tryGetValue(K,V)(const V[K] aa, const K key, out V value) {
    auto v = key in aa;
    if (v is null) {
        return false;
    }
    value = *v;
    return true;
}

// DLANG "bug": an error in this template appears
//              again and again as compilation error for each instantiation
//              This is distracting and confusing.
struct HashSet(T) {
    int[T] _dict;

    this(T[] arr) {
        _dict = arr.map!(p => tuple(p, 0)).assocArray;
    }

    private this(int[T] d) {
        _dict = d;
    }

    bool add(T val) {
        auto prev = val in _dict;
        _dict[val] = 0;
        return prev is null;
    }

    bool remove(T val) {
        return _dict.remove(val);
    }

    auto length() {
        return _dict.length;
    }

    bool opBinaryRight(string op)(const T val) const {
        static if (op == "in") {
            return (val in _dict) !is null;
        } else {
            static assert(false, "Operator " ~ op ~ " not implemented");
        }
    }

    HashSet!T dup() {
        HashSet!T copy;
        copy._dict = _dict.dup;
        return copy;
    }

    HashSet!T dup() const {
        // DLANG BUG: .dup of an AA retains the constness
        // of its parameter, so the output is still const, 
        // and so we can't write a dup() const here.
        // Presumably this is because we can't guarantee the
        // constness of both keys and values.
        // Perhaps there should be an "idup" for AAs.
        int[T] dict;
        foreach(kv; _dict.byKeyValue) {
            dict[kv.key] = kv.value;
        }
        return HashSet(dict);
    }

    static HashSet!T fromArray(T[] arr) {
        return HashSet(arr.map!(p => tuple(p, 0)).assocArray);
    }

    // 1) DLANG template gotcha:
    // If this was:
    // RangeImpl!T opSlice(T)()
    // then it would compile with the error:
    //  "cannot deduce function from argument types `!()()`"
    // I think because the extra (T) overshadows the parent class' (T) type
    // and is really unnecessary here.
    // 
    // 2) DLANG trick: use "inout" modifier on member,
    //    this transfers the mutability/immutability/constness
    //    of "this" to the returned value.
    RangeImpl!T opSlice() inout {
        return RangeImpl!T(_dict);
    }

    // DLANG TRICK: The following wrapper around AA's byKey()
    // compiles only when using typeof(). The idea
    // was to return it from opSlice, below, to avoid
    // the extra allocation that keys() incurs.
    // I tried Alias!() etc. but typeof() was the correct one
    // to use.
    struct RangeImpl(T) {
        typeof( ( const(int[T]) ).init.byKey ) keyRange;
        this(const int[T] d) {
            keyRange = d.byKey();
        }
        bool empty() {
            return keyRange.empty;
        }
        ref T front() {
            return keyRange.front;
        }
        void popFront() {
            keyRange.popFront();
        }
    }
}


auto deltas = [Pnt(0,-1), Pnt(0,1), Pnt(-1,0), Pnt(1,0)];
Pnt add(Pnt p1, Pnt p2) {
   return Pnt(p1.x+p2.x, p1.y+p2.y);
}

// Build the graph, disregarding doors
Pnt[][Pnt] buildGraph(dchar[Pnt] maze, Pnt start) {

    Pnt[][Pnt] graph;

    void dfs(Pnt cur) {
        deltas
        .map!(d => add(cur, d))
        .filter!(p => maze.get(p, '#') != '#')
        .each!( (newPoint)  {
            graph[cur] ~= newPoint;
            if (newPoint !in graph)
                dfs(newPoint);
        });
        // DLANG BUG: Why can't the following be used instead of the .each!() above?
        // using it causes the program to hang.
        // 
        // .tee!(p => graph[cur] ~= p)
        // .filter!(p => p !in graph)
        // .each!(p => dfs(p));
    }
    
    dfs(start);    
    return graph;
}

// Important characteristics of the shortest route from key a to b.
struct Route {
    HashSet!dchar doors; // Doors on the route
    HashSet!dchar keys;  // Other keys encountered on the route
    uint steps;
}

struct Locations {
    Pnt[dchar] keyToPoint;
    dchar[Pnt] pointToKey;
    Pnt[dchar] doorToPoint;
    dchar[Pnt] pointToDoor;
}

struct GraphData {
    const Pnt[][Pnt] graph;
    Pnt[] keys;
    HashSet!Pnt keysHash;
}

GraphData preAllocateGraphData(const Pnt[][Pnt] graph) {
    GraphData g = { graph };
    g.keys = graph.keys;
    g.keysHash = HashSet!Pnt.fromArray(g.keys);
    return g;
}

Route[dchar] dijkstraShortestToAllOtherKeys(const Pnt start, GraphData graphData, Locations locs) {
    import std.container.binaryheap;
    auto graph = graphData.graph;

    // Build shortest routes assuming there aren't any doors, but keep track
    // of doors we see along the way.
    Pnt[] heapStore;
    heapStore.reserve(graphData.keys.length);
    int[Pnt] dist;
    Pnt[Pnt] prev;
    auto comp = (Pnt a, Pnt b) => dist.get(a, int.max) > dist.get(b, int.max); 
    auto heap = BinaryHeap!(Pnt[], comp)(heapStore);
    auto keysHash = graphData.keysHash.dup;

    // OLD, non-performant code, without a priority queue:
    // Pnt[] q = graph.keys; // Should be a priority queue
    // HashSet!Pnt qAA = HashSet!Pnt.fromArray(q);

    dist[start] = 0;
    heap.insert(start);
    dchar[Pnt] remainingKeys = locs.pointToKey.dup;
    remainingKeys.remove(start);
    dchar[Pnt] pointsToOtherKeys = remainingKeys.dup;
    
    while(!heap.empty) {
        // OLD, non-performant code, without a priority queue:
        // auto minIndx = q.minIndex!( (a, b) => dist.get(a, int.max) < dist.get(b, int.max));
        // auto u = q[minIndx];
        // q = q.remove(minIndx);

        auto u = heap.removeAny;
        keysHash.remove(u);
        // We can stop if we've gotten to all other keys
        if (remainingKeys.remove(u) && remainingKeys.length == 0) {
            break;
        }
        foreach(neighbor; graph[u].filter!(pnt => pnt in keysHash)) {
            auto alt = dist.get(u, int.max - 1) + 1; // 1 = distance between any two nodes (node == square)
            if (alt < dist.get(neighbor, int.max)) {
                dist[neighbor] = alt;
                prev[neighbor] = u;
                heap.insert(neighbor);
            }
        }
    } // while

    Route[dchar] targetKeyToRoute;
    foreach(targetKV; pointsToOtherKeys.byKeyValue) {
        Route route;
        Pnt next = targetKV.key;
        while(next != start) {
            route.steps++;
            dchar* door = next in locs.pointToDoor;
            if (door !is null) {
                route.doors.add(*door);
            }
            dchar* otherKey = next in pointsToOtherKeys;
            if (otherKey !is null) {
                route.keys.add(*otherKey);
            }
            next = prev[next];
        }
        
        targetKeyToRoute[targetKV.value] = route;
    }    
    return targetKeyToRoute;
}



Route[dchar][Pnt] buildKeysToRoutes(dchar[Pnt] maze, Locations locs, Pnt start) {
    Route[dchar][Pnt] keyToRoutes;
    Pnt[][Pnt] graph = buildGraph(maze, start);
    GraphData graphData = preAllocateGraphData(graph);
    io.writeln("Graph built");
    // Add routes from initial robot position to all keys
    keyToRoutes[start] = dijkstraShortestToAllOtherKeys(start, graphData, locs);
    // Add routes from all keys to all other keys
    auto keysLocations = locs.keyToPoint.byValue;
    foreach(keyLoc; keysLocations) {
        keyToRoutes[keyLoc] = dijkstraShortestToAllOtherKeys(keyLoc, graphData, locs);
    }
    io.writeln("Routes built");
    return keyToRoutes;
}

class State {
    const Locations locs;
    HashSet!dchar doors;
    HashSet!dchar keys;
    Pnt robotLoc;
    uint steps;
    uint treeDepth; // For debugging only
    this(const Locations locs) {
        this.locs = locs;
    }
}

void drawMaze(const dchar[Pnt] maze, int indent, const State state) {
    auto minx = maze.keys.map!(p => p.x).minElement;
    auto maxx = maze.keys.map!(p => p.x).maxElement;
    auto miny = maze.keys.map!(p => p.y).minElement;
    auto maxy = maze.keys.map!(p => p.y).maxElement;
    foreach(y; miny..maxy+1) {
        foreach(_; 0..indent) 
            io.write(' ');
        foreach(x; minx..maxx+1) {
            Pnt p = Pnt(x, y);
            dchar door, key;
            if (maze[p] == '@')
                io.write('.');
            else if (p == state.robotLoc)
                io.write('@');
            else if ((state.locs.pointToDoor.tryGetValue(p, door) && door !in state.doors) ||
                (state.locs.pointToKey.tryGetValue(p, key) && key !in state.keys)) {
                io.write('.');
            } else {
                io.write(maze[p]);
            }
        }
        io.writeln();
    }
}

struct MazeData {
    const dchar[Pnt] maze; // Only used for debugging to print the maze state at each step
    const Route[dchar][Pnt] keyToRoutes;
    uint[string] keysAndDoorsToNumStepsCache;
    // uint[string] keysAndDoorsToTotalStepsCache;
}

uint step(const State state, ref MazeData mazeData) {
    const Route[dchar][Pnt] keyToRoutes = mazeData.keyToRoutes;

    // const dchar[Pnt] maze = mazeData.maze;
    // drawMaze(maze, state.treeDepth, state);

    // Get reachable keys based on current closed doors
    auto routesToOtherKeys = keyToRoutes[state.robotLoc];
    // io.writeln("considering routes from " ~ toStr(state.robotLoc));
    // io.writeln(routesToOtherKeys);

    // DLANG BUG:  (NOT relevant to current code as it is since I changed the design):
    //             When "door" was of the explicit type "bool[dchar]" (note that currently it's a HashSet but still implemented as an AA)
    //             then "doors.all!(d => d !in state.doors)"  compiled fine. It shouldn't have,
    //             since doors is an AA and the "all" function shouldn't have been able to compile
    //             with "d" as a key in state.doors.  Maybe the "!in" operator is too permissive, or 
    //             there's some sort of implicit conversion between the key-value of doors 
    //             (of type HashSet!dchar) and dchar, which doesn't do the correct thing.

    // Include this only if all currently locked doors are NOT in route
    // kv.Value.doors - doors in route.
    // state.doors - currently locked doors.
    auto unblockedRoutes = routesToOtherKeys.byKeyValue
        .filter!(kv => kv.key in state.keys && kv.value.doors[].all!(d => d !in state.doors));
    auto minSteps = uint.max;
    foreach(route; unblockedRoutes) {
        // io.writeln("Considering route to " ~ route.key.text);
        State newState = new State(state.locs);
        newState.robotLoc = state.locs.keyToPoint[route.key];
        // io.writeln("Prev steps = ", state.steps, ", route delta = ", route.value.steps, ", total = ", state.steps + route.value.steps);
        newState.steps = state.steps + route.value.steps;
        newState.doors = state.doors.dup;
        newState.keys = state.keys.dup;
        newState.treeDepth = state.treeDepth + 1;
        foreach(key; route.value.keys[]) {
            auto door = key - 'a' + 'A';
            newState.doors.remove(door);
            newState.keys.remove(key);
        }
        if (newState.keys.length == 0) {
            // io.writeln("returning, no keys, ", newState.steps);
            return newState.steps;
        }
        // The key to the cache relies on both the (1) current position and (2) current keys
        // For (1), since the algorithm consists of "walking from key to key" then the name of the key we currently consider
        // going to can be used as the location (route.key is a dchar)
        string keysAndDoors = route.key.to!string ~ " " ~ newState.keys[].array.sort.to!string;
        uint* cachedDeltaSteps = keysAndDoors in mazeData.keysAndDoorsToNumStepsCache;
        uint stepsFromSubState;
        if (cachedDeltaSteps is null) {
            // io.writeln(keysAndDoors ~ " not found in cache, recursing into " ~ (newState.robotLoc).toStr);
            stepsFromSubState = step(newState, mazeData);
            // io.writeln("caching " ~ keysAndDoors ~ " -> " ~ stepsFromSubState.to!string ~ " - " ~ newState.steps.to!string);
            mazeData.keysAndDoorsToNumStepsCache[keysAndDoors] = stepsFromSubState - newState.steps;
        } else {
            stepsFromSubState = newState.steps + *cachedDeltaSteps;
            // io.writeln(keysAndDoors ~ " found in cache, using num of steps " ~ (*cachedDeltaSteps).to!string ~
                // " -> " ~ stepsFromSubState.to!string);
        }

        minSteps = min(minSteps, stepsFromSubState);
    } // foreach(route)
    // io.writeln("returning ", minSteps);

    return minSteps;
}

void main() {

    dchar[Pnt] inputMaze;
    Locations locs;
    Pnt[][Pnt] graph;
    Pnt startPoint;

    auto lines = io.stdin.byLineCopy.array;
    // string[] lines = io.File("day18_1_input.txt").byLine.map!(to!string).array;
    import std.uni: isLower;
    foreach (j, line; lines) { 
        foreach(i, c; line) {
            Pnt p = Pnt(i, j);
            inputMaze[p] = c;
            if (c == '@') {
                startPoint = p;
            } else if (c != '#' && c != '.') {
                with (locs) {
                    if (c.isLower) {
                        keyToPoint[c] = p;
                        pointToKey[p] = c;
                    } else {
                        doorToPoint[c] = p;
                        pointToDoor[p] = c;
                    }
                }
            }
        }
    }

    // io.writeln(startPoint);
    // io.writeln(locs.keyToPoint.keys.sort.array);
    // io.writeln(locs.doorToPoint.keys.sort.array);

    auto keyToRoutes = buildKeysToRoutes(inputMaze, locs, startPoint);
    // return;
    State initalState = new State(locs);
    with(initalState) {
        doors = HashSet!dchar.fromArray(initalState.locs.doorToPoint.keys);
        keys = HashSet!dchar.fromArray(initalState.locs.keyToPoint.keys);
        robotLoc = startPoint;
        steps = 0;
        treeDepth = 0;
    }
    auto mazeData = MazeData(inputMaze, keyToRoutes);
    auto minSteps = step(initalState, mazeData);
    io.writeln(minSteps);
}