module day24;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;
import std.concurrency : Generator, yield;

struct Point {
    long x, y;
    Point opBinary(string op)(Point p2) {
        static if (op == "+") {
            return Point( this.x + p2.x, this.y + p2.y );
        } else static assert(false, "Operator not supported");
    }
}
Point[4] deltas = [ {-1, 0}, {1, 0}, {0, 1}, {0, -1}];

Generator!Point getBoardPoints(byte[Point] board, void delegate() betweenLines = null) {
    const boardSize = board.byKey.map!(p => p.x).maxElement + 1;
    return new Generator!Point( {
        foreach(j; 0..boardSize) {
            foreach(i; 0..boardSize) {
                yield(Point(j, i));
            }
            if (betweenLines != null) 
                betweenLines();
        }
    });
}

// For debugging
void printBoard(byte[Point] board) {
    foreach(p; getBoardPoints(board, () => io.writeln)) {
        io.write( (board.get(p, 0) == 1) ? '#': '.');
    }
}

void part1(byte[Point] board) {
    byte[Point][2] boards;
    // Assume square board
    long boardSize = board.keys.map!(p => p.x).maxElement + 1;
    boards[0] = board.dup;
    boards[1] = board.dup;
    bool running = true;
    size_t curBoardIndex = 0;
    bool[ulong] knownLayouts;
    ulong result;
    while(running) {
        auto curBoard = boards[curBoardIndex];
        // Cache current board configuration
        ulong boardBits;
        ulong bit = 1;
        foreach(p; getBoardPoints(board)) {
            if (curBoard.get(p, 0) == 1) {
                boardBits |= bit;
            }
            bit <<= 1;
        }
        running = (boardBits in knownLayouts) == null;
        if (!running) {
            result = boardBits;
            break;
        }
        knownLayouts[boardBits] = true;

        auto nextBoardIndex = (curBoardIndex + 1) % 2;
        auto nextBoard = boards[nextBoardIndex];
        foreach(p; getBoardPoints(board)) {
            int sumNeighbors = deltas[].map!( d => curBoard.get(d + p, 0) ).sum;
            byte curCell = curBoard.get(p, 0);
            if (curCell == 1 && sumNeighbors != 1) {
                nextBoard[p] = 0;
            }
            else if (curCell == 0 && (sumNeighbors == 1 || sumNeighbors == 2)) {
                nextBoard[p] = 1;
            } else {
                nextBoard[p] = curCell;
            }
        }
        // printBoard(nextBoard); io.writeln;
        curBoardIndex = nextBoardIndex;
    }
    io.writeln(result);
}

struct Point3(long boardSize) {
    long x, y, level;
    enum middle = boardSize / 2;
    // Adding a delta can return many neighboring points

    Point3[] opBinary(string op)(Point delta) {
        static if (op == "+") {
            auto newX = x + delta.x;
            auto newY = y + delta.y;
            Point3!boardSize[] points;

            if (newX == middle && newY == middle) {
                if (delta.x == 1) {
                    foreach(yloop; 0..boardSize) {
                        points ~= Point3!boardSize(0, yloop, level + 1);
                    }
                } else if (delta.x == -1) {
                    foreach(yloop; 0..boardSize) {
                        points ~= Point3!boardSize(boardSize - 1, yloop, level + 1);
                    }
                } else if (delta.y == 1) {
                    foreach(xloop; 0..boardSize) {
                        points ~= Point3!boardSize(xloop, 0, level + 1);
                    }
                } else if (delta.y == -1) {
                    foreach(xloop; 0..boardSize) {
                        points ~= Point3!boardSize(xloop, boardSize - 1, level + 1);
                    }
                }
            } else {
                long levelDelta = 0;
                // Just a single point in this delta
                void adjust(ref long coor, ref long other) {
                    if (coor < 0) {
                        coor = middle - 1;
                        other = middle;
                        levelDelta = -1;
                    } else if (coor >= boardSize) {
                        coor = middle + 1;
                        other = middle;
                        levelDelta = -1;
                    }
                }
                adjust(newX, newY);
                adjust(newY, newX);
                points ~= Point3!boardSize(newX, newY, level + levelDelta);
            }
            return points;
        } else static assert(false, "Operator not supported");
    }
}


Point3!boardSize[] getNeighbors(long boardSize)(Point3!boardSize p) {
    Point3!boardSize[] neighbors;
    foreach(d; deltas) {
        neighbors ~= p + d;
    }
    return neighbors;
}

unittest {
    /*
    |     |     |         |     |     
    1  |  2  |    3    |  4  |  5  
        |     |         |     |     
    -----+-----+---------+-----+-----
        |     |         |     |     
    6  |  7  |    8    |  9  |  10 
        |     |         |     |     
    -----+-----+---------+-----+-----
        |     |A|B|C|D|E|     |     
        |     |-+-+-+-+-|     |     
        |     |F|G|H|I|J|     |     
        |     |-+-+-+-+-|     |     
    11  | 12  |K|L|?|N|O|  14 |  15 
        |     |-+-+-+-+-|     |     
        |     |P|Q|R|S|T|     |     
        |     |-+-+-+-+-|     |     
        |     |U|V|W|X|Y|     |     
    -----+-----+---------+-----+-----
        |     |         |     |     
    16  | 17  |    18   |  19 |  20 
        |     |         |     |     
    -----+-----+---------+-----+-----
        |     |         |     |     
    21  | 22  |    23   |  24 |  25 
        |     |         |     |     
    |
    */
    // DLANG BUG: Point3 is a template, but : 
    // - first statement below passes compilation 
    // - second statement fails compilation with a confusing error (Error: found `p19` when expecting `;` following statement)
    // Point3[] neighbors;
    // Point3 p19(3, 3, 0);

    alias Point3Impl = Point3!5;

    //  * Tile 19 has four adjacent tiles: 14, 18, 20, and 24.
    Point3Impl[] neighbors;
    neighbors = getNeighbors(Point3Impl(3, 3, 0));
    assert(neighbors.any!(p => p == Point3Impl(3, 2, 0))); // 14
    assert(neighbors.any!(p => p == Point3Impl(2, 3, 0))); // 18
    assert(neighbors.any!(p => p == Point3Impl(4, 3, 0))); // 20
    assert(neighbors.any!(p => p == Point3Impl(3, 4, 0))); // 24
    
    //   * Tile G has four adjacent tiles: B, F, H, and L.
    neighbors = getNeighbors(Point3Impl(1, 1, 1));
    assert(neighbors.any!(p => p == Point3Impl(1, 0, 1))); // B
    assert(neighbors.any!(p => p == Point3Impl(0, 1, 1))); // F
    assert(neighbors.any!(p => p == Point3Impl(2, 1, 1))); // H
    assert(neighbors.any!(p => p == Point3Impl(1, 2, 1))); // L

    //   * Tile D has four adjacent tiles: 8, C, E, and I.
    neighbors = getNeighbors(Point3Impl(3, 0, 1));
    assert(neighbors.any!(p => p == Point3Impl(2, 1, 0))); // 8
    assert(neighbors.any!(p => p == Point3Impl(2, 0, 1))); // C
    assert(neighbors.any!(p => p == Point3Impl(4, 0, 1))); // E
    assert(neighbors.any!(p => p == Point3Impl(3, 1, 1))); // I

    //   * Tile E has four adjacent tiles: 8, D, 14, and J.
    neighbors = getNeighbors(Point3Impl(4, 0, 1));
    assert(neighbors.any!(p => p == Point3Impl(2, 1, 0))); // 8
    assert(neighbors.any!(p => p == Point3Impl(3, 2, 0))); // 14
    assert(neighbors.any!(p => p == Point3Impl(3, 0, 1))); // D
    assert(neighbors.any!(p => p == Point3Impl(4, 1, 1))); // J

    //   * Tile 14 has /eight/ adjacent tiles: 9, E, J, O, T, Y, 15, and 19.
    neighbors = getNeighbors(Point3Impl(3, 2, 0));
    assert(neighbors.any!(p => p == Point3Impl(3, 1, 0))); // 9
    assert(neighbors.any!(p => p == Point3Impl(4, 0, 1))); // E
    assert(neighbors.any!(p => p == Point3Impl(4, 1, 1))); // J
    assert(neighbors.any!(p => p == Point3Impl(4, 2, 1))); // O
    assert(neighbors.any!(p => p == Point3Impl(4, 3, 1))); // T
    assert(neighbors.any!(p => p == Point3Impl(4, 4, 1))); // Y
    assert(neighbors.any!(p => p == Point3Impl(3, 3, 0))); // 19

    //   * Tile N has /eight/ adjacent tiles: I, O, S, and five tiles within
    //     the sub-grid marked |?|.
    neighbors = getNeighbors(Point3Impl(3, 2, 1));
    io.writeln(neighbors);
    assert(neighbors.any!(p => p == Point3Impl(3, 1, 1))); // I
    assert(neighbors.any!(p => p == Point3Impl(4, 2, 1))); // O
    assert(neighbors.any!(p => p == Point3Impl(3, 3, 1))); // S
}

Generator!(Point3!boardSize) getBoardPoints3(long boardSize)(long level, void delegate() betweenLines = null) {
    return new Generator!(Point3!boardSize)( {
        foreach(j; 0..boardSize) {
            foreach(i; 0..boardSize) {
                yield(Point3!boardSize(j, i, level));
            }
            if (betweenLines != null) 
                betweenLines();
        }
    });
}

// For debugging
void printBoardPoint3(long boardSize)(byte[Point3!boardSize] board, long minLevel, long maxLevel) {
    foreach(level; minLevel..maxLevel + 1) {
        io.writeln("Level ", level);
        foreach(p3; getBoardPoints3!boardSize(level, () => io.writeln)) {
            io.write( (board.get(p3, 0) == 1) ? '#': '.');
        }
    }
}

void part2(byte[Point] board, size_t rounds) {
    enum boardSize = 5;
    alias Point3Impl = Point3!boardSize;

    long minLevel = -1;
    long maxLevel = 1;
    byte[Point3Impl][2] boards;
    // Transform the (x,y) points into (x,y,level=0) points
    board.byKeyValue.each!(kv => boards[0][Point3Impl(kv.key.x, kv.key.y, 0)] = kv.value);
    // printBoardPoint3(boards[0], minLevel, maxLevel);
    boards[1] = boards[0].dup;
    size_t curBoardIndex = 0;
    foreach(round; 0..rounds) {
        auto curBoard = boards[curBoardIndex];
        auto nextBoardIndex = (curBoardIndex + 1) % 2;
        auto nextBoard = boards[nextBoardIndex];
        bool moveMinLevel = false;
        bool moveMaxLevel = false;
        foreach(level; minLevel..maxLevel + 1) {
            auto points = getBoardPoints3!boardSize(level)
                // filter out the middle point
                .filter!(p => ! (p.x == boardSize / 2 && p.y == boardSize /2));
            foreach(p; points) {
                // getNeighbors does the heavy lifting here, it returns all neighbors, 
                // by calling the "+" operator for each delta direction. The "+" operator returns
                // a list of neighbors for each direction.
                int sumNeighbors = getNeighbors(p).map!(neighbor => curBoard.get(neighbor, 0)).sum;
                byte curCellVal = curBoard.get(p, 0);
                if (curCellVal == 1 && sumNeighbors != 1) {
                    nextBoard[p] = 0;
                }
                else if (curCellVal == 0 && (sumNeighbors == 1 || sumNeighbors == 2)) {
                    nextBoard[p] = 1;
                    // Check if we just filled up a position in the min level, if so
                    // in the next round we need to consider the level below that.
                    // Ditto for the max level.
                    if (p.level == minLevel) {
                        moveMinLevel = true;
                    } else if (p.level == maxLevel) {
                        moveMaxLevel = true;
                    }
                } else {
                    nextBoard[p] = curCellVal;
                }
            }
        }
        // io.writeln("----------------------------------");
        // printBoardPoint3(nextBoard, minLevel, maxLevel);
        if (moveMinLevel) {
            minLevel -= 1;
        }
        if (moveMaxLevel) {
            maxLevel += 1;
        }
        curBoardIndex = nextBoardIndex;
    }

    // Should return number of bugs, that is, number of cells which has 1. Do this by simply
    // counting them.
    auto result = boards[curBoardIndex].byValue.sum;
    io.writeln(result);
}


void main() {
    byte[Point] board;
    Point a, b;
    Point d = a + b;
    io.stdin.byLineCopy.array
        .each!( (j, line) => line
            .each!( (i, c) { if (c == '#') { 
                board[Point(j, i)] = 1; }}));
    // printBoard(board);

    part1(board);
    part2(board, 200);
}