module day20;
import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;
import std.uni: isUpper;

alias Pnt = Tuple!(long, "x", long, "y");

Pnt add(Pnt p1, Pnt p2) {
   return Pnt(p1.x+p2.x, p1.y+p2.y);
}

struct Queue(T) {
    T[] arr;
    uint tail_ = 0;
    uint head_ = 0;
    bool empty_ = true;

    this(size_t maxSize) {
        arr.length = maxSize;
    }
    void enqueue(T val) {
        if (!empty_ && head_ == tail_) {
            throw new Exception("Full queue");
        }
        arr[head_] = val;
        head_ = (head_ + 1) % arr.length;
        empty_ = false;
    }
    T deque() {
        if (tail_ == head_) {
            throw new Exception("Empty queue");
        }
        T val = arr[tail_];
        tail_ = (tail_ + 1) % arr.length;
        empty_ = tail_ == head_;
        return val;
    }
    bool empty() {
        return empty_;
    }
}

// An implementation of C# (or rather the BCL's) Dictionary.TryGetValue() method, which I rather like.
bool tryGetValue(K,V)(const V[K] aa, const K key, out V value) {
    auto v = key in aa;
    if (v is null) {
        return false;
    }
    value = *v;
    return true;
}

// For part 1
int bfs1(const dchar[Pnt] maze, const Pnt start, const Pnt end, const Pnt[Pnt] portalPointToOther) {
    Pnt[Pnt] route;
    bool[Pnt] visited;

    auto queue = Queue!(Pnt)(maze.length);
    queue.enqueue(start);
    visited[start] = true;
    bool finished = false;
    while(!queue.empty && !finished) {
        auto cur = queue.deque;
        debug(1) { io.writeln("cur = ", cur); }
        Pnt otherPortalPoint;
        const deltas = [Pnt(0,-1), Pnt(0,1), Pnt(-1,0), Pnt(1,0)];
        auto around = deltas
            // Look around using deltas
            .map!(d => add(cur, d))
            // Add to the list of possible points, the one we go through the portals for (or an empty list - Pnt[].init
            // if we aren't on a portal point).
            .chain(choose(portalPointToOther.tryGetValue(cur, otherPortalPoint), only(otherPortalPoint), Pnt[].init))
            .filter!(p => p !in visited && maze.get(p, '#') != '#');
        foreach(p; around) {
            debug(1) { io.writeln("  considering = ", p); }
            visited[p] = true;
            queue.enqueue(p);
            route[p] = cur;
            finished = p == end;
        }
    }

    int length;
    Pnt cur = end;
    while(cur != start) {
        cur = route[cur];
        length++;
    }
    return length;
}

// For debugging only
string[Pnt] pointToPortal;

// For part 2
int bfs2(const dchar[Pnt] maze, const Pnt start, const Pnt end, const Pnt[Pnt] portalPointToOther, const Pnt maxXY) {

    alias PntAndLayer = Tuple!(Pnt, "p", int, "layer");
    PntAndLayer[PntAndLayer] route;
    bool[PntAndLayer] visited;

    bool isOuterPortal(const Pnt p) {
        return (p.x == 2 || p.y == 2 || p.x == maxXY.x - 2 || p.y == maxXY.y - 2);
    }

    int getLayerDelta(const PntAndLayer pl) {
        if (pl.p in portalPointToOther) {
            return isOuterPortal(pl.p) ? -1 : 1;
        } else {
            return 0;
        }
    }
    
    bool isLegalPoint(const Pnt p) {
        auto c = maze.get(p, '#');
        return c != '#' && !c.isUpper;
    }
    bool[Pnt] deadEnds;

    auto startLayered = PntAndLayer(start, 0);
    auto endLayered = PntAndLayer(end, 0);

    auto queue = Queue!(PntAndLayer)(maze.length * 10);
    queue.enqueue(startLayered);

    visited[startLayered] = true;
    bool finished = false;

    while(!queue.empty && !finished) {
        auto cur = queue.deque;
        debug(1) {
            io.writeln("cur = ", cur);
            if (cur.p in pointToPortal) {
                io.writeln("cur = ", cur);
                io.writeln("In ", (isOuterPortal(cur.p) ? "outer" : "inner"), " portal, ", pointToPortal[cur.p], " ", cur.layer); 
            }
        }
        const deltas = [Pnt(0,-1), Pnt(0,1), Pnt(-1,0), Pnt(1,0)];

        if (cur.p !in portalPointToOther && cur.p != startLayered.p && cur.p != endLayered.p &&
                deltas.map!(d => cur.p.add(d)).count!(p => isLegalPoint(p) && p !in deadEnds) == 1) {
            // Optimization: cull dead ends (cuts time by as much as 50% on the large input maze).
            // For all points around: 
            // If the count of the legal points around, minus known deadends == 1 then it's a deadend itself,
            // unless it's a portal, which is never considered as one.
            // This isn't the most efficient culling since 
            // 1) We could use the map and filter results below as well.
            // 2) we can in principle cull away the whole current dead-end sub-graph. 
            // Instead the sub-graph will be culled square by square each time we will get to a square
            // adjacent to a known dead-end.  However it is quick enough.
            deadEnds[cur.p] = true;
        }

        Pnt otherPortalPoint;
        auto around = deltas
            // Look around using deltas
            .map!(d => PntAndLayer( cur.p.add(d), cur.layer ))
            // Add to the list of possible points the one we go through the portals for, or an empty list 
            // if we aren't on a portal point.
            .chain(choose(
                portalPointToOther.tryGetValue(cur.p, otherPortalPoint), 
                only(PntAndLayer(otherPortalPoint, cur.layer + getLayerDelta(cur))),
                PntAndLayer[].init))
            // .tee!( (pl) { debug(1) io.writeln("   Checking ", pl); } )
            .filter!(pl => pl.layer >= 0 && pl !in visited && isLegalPoint(pl.p) && pl.p !in deadEnds);

        foreach(pl; around) {
            debug(1) { io.writeln("  considering = ", pl); }
            visited[pl] = true;
            queue.enqueue(pl);
            route[pl] = cur;
            finished = (pl.p == endLayered.p && pl.layer == endLayered.layer);
            if (finished) {
                break;
            }
        }
    }

    int length;
    auto cur = endLayered;
    while(cur != startLayered) {
        cur = route[cur];
        length++;
    }

    return length;
}


void main() {
    auto lines = io.stdin.byLineCopy.array;
    dchar[Pnt] inputMaze;
    Tuple!(Pnt, string)[] portalEdges;

    foreach (j, line; lines) {
        foreach(i, c; line) {
            Pnt p = Pnt(i, j);
            if (c.isUpper) {
                // Letter label can be one above or one to the left of the current letter
                const deltas = [ Pnt(0, -1), Pnt(-1, 0) ];
                auto otherLetterRange = deltas
                    .map!(d => inputMaze.get(p.add(d), '$')) // '$' is just used here because it's not an uppercase letter
                    .filter!(other => other.isUpper)
                    .takeOne;
                if (otherLetterRange.length == 1) {
                    string portal = otherLetterRange.front.to!string ~ c;
                    // portalEdges is a temporary array, we need it because we cannot yet know 
                    // the actual portal point, since we're still scanning the maze here,
                    // e.g. if we're in the case (1) below, in the character marked by the arrow below, we know that
                    // are in a portal, but since the line below hasn't been read yet, we can't know for sure
                    // where the actual portal is.
                    // 
                    // (1)
                    //  A           
                    //  A  <---
                    // #.#
                    //
                    // (2)
                    // #.#
                    //  Z
                    //  Z
                    portalEdges ~= tuple(p, portal);
                }
            }
            if (c != ' ') {
                inputMaze[p] = c;
            }
        }
    }
    Pnt[][string] portalToPoints;
    Pnt[Pnt]      portalPointToOther; // For part 1

    foreach(portalEdge; portalEdges) {
        const p = portalEdge[0];
        const portalName = portalEdge[1];
        // The following deltas are for the following cases:
        // (1)
        //  A           
        //  A  <--- We know this is a portal's edge 
        // #.# <--- We need this '.' point, delta = (0,1)
        // 
        // (2)
        // #.#  <-- We need this '.' point, delta = (0, -2)
        //  Z   
        //  Z   <--- We know this is a portal's edge 
        //
        // Similarly for horizontal portal names.
        const deltasForPoint = [ Pnt(0, 1), Pnt(1, 0), Pnt(0, -2), Pnt(-2, 0)];
        // DLANG BUG: calling .front on an empty .filter!() crashes (which it should)
        //            but the crash stack has no call stack line in my own code.
        auto portalPoint = deltasForPoint
            .map!(d => p.add(d))
            .filter!(pd => inputMaze.get(pd, '$') == '.') // '$' is just used as something that isn't a '.'
            .front;
        Pnt[] portalPoints = portalToPoints.require(portalName, Pnt[].init);
        portalPoints ~= portalPoint;
        if (portalPoints.length == 2) {
            portalPointToOther[portalPoints[0]] = portalPoints[1];
            portalPointToOther[portalPoints[1]] = portalPoints[0];
        }
        portalToPoints[portalName] ~= portalPoint;
    }

    auto startPnt = portalToPoints["AA"][0];
    auto endPnt = portalToPoints["ZZ"][0];

    foreach(kv; portalToPoints.byKeyValue) {
        foreach(p; kv.value) {
            pointToPortal[p] = kv.key;
        }
    }

    int result;
    result = bfs1(inputMaze, startPnt, endPnt, portalPointToOther);
    io.writeln(result);

    auto maxPnt = Pnt(lines[0].length - 1, lines.length - 1);
    result = bfs2(inputMaze, startPnt, endPnt, portalPointToOther, maxPnt);
    io.writeln(result);
}
