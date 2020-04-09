module day22;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;
import std.variant;

struct Dealnew {
}

struct Dealinc {
    long n;
}

struct Cut {
    long n;
}

alias Technique = Algebraic!(Dealnew, Dealinc, Cut);
ulong[] shuffle(Technique[] techniques, int size) {
    auto deck = new ulong[size];
    auto temp = new ulong[size];
    foreach (i; 0 .. size) {
        deck[i] = i;
    }
    foreach (t; techniques) {
        auto dn = t.peek!Dealnew;
        auto di = t.peek!Dealinc;
        auto cut = t.peek!Cut;
        if (dn !is null) {
            deck.reverse;
        } else if (di !is null) {
            size_t ind;
            foreach (i; 0 .. size) {
                temp[ind] = deck[i];
                ind = ((ind + di.n) % size).to!size_t;
            }
            deck[] = temp[];
        } else if (cut !is null) {
            auto n = ((cut.n < 0) ? (size - -cut.n) : cut.n).to!uint;
            bringToFront(deck[0 .. n], deck[n .. $]);
        }
    }
    return deck;
}

unittest {
    {
        Technique[] techniques = [Technique(Cut(3))];
        auto result = shuffle(techniques, 10);
        io.writeln(result);
        assert(result == [3, 4, 5, 6, 7, 8, 9, 0, 1, 2]);
    }
    {
        Technique[] techniques = [Technique(Cut(-4))];
        auto result = shuffle(techniques, 10);
        io.writeln(result);
        assert(result == [6, 7, 8, 9, 0, 1, 2, 3, 4, 5]);
    }
    {
        Technique[] techniques = [Technique(Dealnew())];
        auto result = shuffle(techniques, 10);
        io.writeln(result);
        assert(result == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
    }
    {
        Technique[] techniques = [Technique(Dealinc(3))];
        auto result = shuffle(techniques, 10);
        io.writeln(result);
        assert(result == [0, 7, 4, 1, 8, 5, 2, 9, 6, 3]);
    }
    {
        /*
            deal with increment 7
            deal into new stack
            deal into new stack
            Result: 0 3 6 9 2 5 8 1 4 7        
        */
        Technique[] techniques = [ Technique(Dealinc(7)), Technique(Dealnew()), Technique(Dealnew()), ];
        auto result = shuffle(techniques, 10);
        io.writeln(result);
        assert(result == [0, 3, 6, 9, 2, 5, 8, 1, 4, 7]);
    }

    {
        /*
            deal into new stack
            cut -2
            deal with increment 7
            cut 8
            cut -4
            deal with increment 7
            cut 3
            deal with increment 9
            deal with increment 3
            cut -1
            Result: 9 2 5 8 1 4 7 0 3 6        
            */
        Technique[] techniques = [Technique(Dealnew()), 
            Technique(Cut(-2)), 
            Technique(Dealinc(7)), 
            Technique(Cut(8)), 
            Technique(Cut(-4)), 
            Technique(Dealinc(7)), 
            Technique(Cut(3)),
            Technique(Dealinc(9)), 
            Technique(Dealinc(3)), 
            Technique(Cut(-1)), ];
        auto result = shuffle(techniques, 10);
        io.writeln(result);
        assert(result == [9,2,5,8,1,4,7,0,3,6]);
    }
}

Technique parse(string s) {
    const string cut = "cut ";
    const string dealWith = "deal with increment ";
    if (s.startsWith(cut)) {
        int n = s[cut.length..$].to!int;
        return Technique(Cut(n));
    }
    if (s.startsWith(dealWith)) {
        int n = s[dealWith.length..$].to!int;
        return Technique(Dealinc(n));
    }
    if (s == "deal into new stack") {
        return Technique(Dealnew());
    }
    throw new Exception("Illegal");
}

unittest {
    auto t = parse("cut -7812");
    assert(t == Technique(Cut(-7812)));
    t = parse("deal with increment 55");
    assert(t == Technique(Dealinc(55)));
}

void part1(string[] lines) {
    auto techniques = lines.map!(parse).array;
    auto resultArr = shuffle(techniques, 10007);
    auto result = resultArr.countUntil(2019);
    io.writeln(result);
}

/*
 UNUSED - only used during development for part 2
*/
ulong shuffle2(Technique[] techniques, ulong size, ulong cardToTrack, ulong iterations) {
    /*
    DealNew:
    curLocation = size - curLocation - 1;
    y = size - x - 1
    x = y + 1 - size (mod size)
    
    DealInc(inc):
    reverse:
    E.g. DealInc(3)
    0 1 2 3 4 5 6 7 8 9
    0 7 4 1 8 5 2 9 6 3
    We calculate with O(1) where e.g. 7 will end up.  That is, the card currently in position 7.
    (7 * 3) % 10 = 1
    Reversing that:
    (x * 3) % 10 = y
    x=?
    x*3 = y (mod 10)
    => x = 3^-1 * y (mod 10) = modInverse(3, 10)
    ---
    Which will end up in offset 9?
    (x*3) = 9 (mod 10)
    x = 9 * 3^-1 (mod 10) = 9 * 7 (mod 10) = 3

    Cut(n):
    Cut(3):
    // 0 1 2 3 4 5 6 7 8 9
    // 3 4 5 6 7 8 9 0 1 2
    7 will end up in ((7 - 3) + 10) % 10 = 4
    --> reversing this:
    in place 4, we will have: (4+3) % 10 = -3%10 = 7

    ==>
    cut(p)
    x+p = y (mod 10)
    x = y-p (mod 10)
    */ 
    long curLocation = cardToTrack;
    io.writeln(curLocation);
    techniques.reverse;
    foreach(i; 0..iterations) {
        foreach (t; techniques) {
            auto dn = t.peek!Dealnew;
            auto di = t.peek!Dealinc;
            auto cut = t.peek!Cut;
            if (dn !is null) {
                // x = y + 1 - size (mod size)
                // -1*curLocation + (-1) (mod 10)
                curLocation = size - curLocation - 1;
            } else if (di !is null) {
                // Should do:
                // curLocation = (curLocation * di.n) % 10;
                // x*3 = y (mod 10)
                // => x = 3^-1 * y (mod 10) = modInverse(3, 10)

                // Original multiplication:
                // curLocation = (curLocation * modInverse(di.n, size)) % size.to!long ;
                io.writeln("modeinverse=", modInverse(di.n, size));
                curLocation = mulMod(curLocation, modInverse(di.n, size), size.to!long);
            } else if (cut !is null) {
                // x = y-p (mod 10)
                curLocation = (curLocation + cut.n) % size.to!long;
            }
            if (curLocation < 0)
                curLocation += size;
            io.writeln(curLocation);
        }
    }
    return curLocation;
}
unittest {
    {
        Technique[] techniques = [Technique(Cut(3))];
        auto result = shuffle2(techniques, 10, 0, 1);
        // assert(result == [3, 4, 5, 6, 7, 8, 9, 0, 1, 2]);
        assert(result == 3);
        result = shuffle2(techniques, 10, 6, 1);
        assert(result == 9);
        result = shuffle2(techniques, 10, 9, 1);
        assert(result == 2);
    }
    {
        Technique[] techniques = [Technique(Cut(-4))];
        auto result = shuffle2(techniques, 10, 0, 1);
        // assert(result == [6, 7, 8, 9, 0, 1, 2, 3, 4, 5]);
        assert(result == 6);
    }
    {
        Technique[] techniques = [Technique(Dealinc(3))];
        // assert(result == [0, 7, 4, 1, 8, 5, 2, 9, 6, 3]);

        auto result = shuffle2(techniques, 10, 1, 1);
        assert(result == 7);
        result = shuffle2(techniques, 10, 2, 1);
        assert(result == 4);
        result = shuffle2(techniques, 10, 9, 1);
        assert(result == 3);
    }
    {
        Technique[] techniques = [Technique(Dealnew())];
        auto result = shuffle2(techniques, 10, 2, 1);
        // assert(result == [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
        assert(result == 7);
    }
    {
        /*
            deal with increment 7
            deal into new stack
            deal into new stack
            Result: 0 3 6 9 2 5 8 1 4 7        
        */
        Technique[] techniques = [ Technique(Dealinc(7)), Technique(Dealnew()), Technique(Dealnew()), ];
        // assert(result == [0, 3, 6, 9, 2, 5, 8, 1, 4, 7]);
        auto result = shuffle2(techniques, 10, 1, 1);
        assert(result == 3);
        result = shuffle2(techniques, 10, 6, 1);
        assert(result == 8);
        result = shuffle2(techniques, 10, 0, 1);
        assert(result == 0);
    }
    {
        /*
            deal into new stack
            cut -2
            deal with increment 7
            cut 8
            cut -4
            deal with increment 7
            cut 3
            deal with increment 9
            deal with increment 3
            cut -1
            Result: 9 2 5 8 1 4 7 0 3 6        
            */
        Technique[] techniques = [Technique(Dealnew()), 
            Technique(Cut(-2)), 
            Technique(Dealinc(7)), 
            Technique(Cut(8)), 
            Technique(Cut(-4)), 
            Technique(Dealinc(7)), 
            Technique(Cut(3)),
            Technique(Dealinc(9)), 
            Technique(Dealinc(3)), 
            Technique(Cut(-1)), ];
        auto result = shuffle2(techniques, 10, 0, 1);
        // assert(result == [9,2,5,8,1,4,7,0,3,6]);
        assert(result == 9);
    }
}
// ======================================================================

// PART 2 SOLUTION
// Based on the execellent explanation here:
// https://codeforces.com/blog/entry/72593
// NOTE: This could have been simplified had I used the standard BigInt.
// However I wanted to avoid using it in order to give myself some extra challenge.
// I also tried to avoid going the full "object oriented" route and create a BigInt class myself.
// This was in retrospect a mistake, since for a long time I kept having integer wrap-around bugs
// that could have been avoided had I used BigInt, had I implemented a (mod) BigInt class myself, or had I
// used the CheckedInt type which would have thrown an error when things wrapped around.

long modInverse(long a, long m) { 
    long m0 = m; 
    long y = 0, x = 1; 
    if (m == 1) 
        return 0; 
    while (a > 1) {
        // q is quotient 
        long q = a / m; 
        long t = m; 
        // m is remainder now, process same as Euclid's algo 
        m = a % m; 
        a = t; 
        t = y; 
        // Update x and y 
        y = x - q * y; 
        x = t; 
    } 
    // Make x positive 
    if (x < 0) 
        x += m0; 
    return x; 
} 

long mulMod(long a, long b, long mod) {
    long sign = (a > 0 && b > 0 || a < 0 && b < 0)  ? 1 : -1;
    if (a < 0) 
        a *= -1;
    if (b < 0)
        b *= -1;
    long res = 0;
    a %= mod;
    if ((a > 0 && a * 2 < a) || (a < 0 && a * 2 > a))
        throw new Exception("a too large");
    while(b > 0) {
        if (b & 1) {
            res = (res + a) % mod;
        }
        a = (2 * a) % mod;
        b >>= 1;
    }
    return res * sign;
}

long expMod(long a, long exp, long mod) {
    if (a == 0)
        return 0;
    if (exp < 0)
        throw new Exception("negative exp not implemented");
    long res = 1;
    while(exp > 0) {
        if (exp & 1) {
            // res = (res * a) % mod;
            res = mulMod(res, a, mod);
        }
        // a = (a * a) % mod;
        a = mulMod(a, a, mod);
        exp >>= 1;
    }
    return res;
}

unittest {
    auto res = expMod(3, 2, 5);
    assert(res == 4);
    res = expMod(9973, 7, 119);
    assert(res == 54);
}

struct Linear { // ax+b
    long a;
    long b;
}

// Linear as in ax+b
Linear getLinear(Technique t, long mod) {
    auto dn = t.peek!Dealnew;
    auto di = t.peek!Dealinc;
    auto cut = t.peek!Cut;
    
    // F(y) = (-1)y - 1
    // G(y) = (di.n)^-1 * y + 0
    // H(y) = 1*y + cut.n
    if (dn !is null) {
        return Linear(-1, -1);
    } 
    else if (di !is null) {
        return Linear(modInverse(di.n, mod), 0);
    }
    else if (cut !is null) {
        return Linear(1, cut.n);
    }
    throw new Exception("Unknown technique");
}

Linear mulLinears(Linear f, Linear g, long mod) {
    // g(f(y)) = ga*(fa*x+fb)+gb = 
    //           ga*fa*x + ga*fb+gb
    return Linear(mulMod(f.a, g.a, mod), (mulMod(g.a, f.b, mod) + g.b) % mod);
}


Linear expLinear(Linear f, long exp, long mod) {
    if (exp == 1)
        return f;
    // f(f(y)) = fa * (fa*y+fb) + fb = 
    //           fa^2*y + fa*fb+fb
    // f(f(f(y))) = fa * (fa^2*y + fa*fb+fb) = 
    //              fa^3*y + fa^2*fb + fa*fb = 
    //              fa^n*y + fb * (fa + fa^2 + fa^3 + ...) = (geometric series)
    //              fa^n*y + fb * (1-fa^n / 1-fa)

    long faExpN = expMod(f.a, exp, mod);
    // (1 - faExpN) / (1 - f.a) == (1 - faExpN) * (1 - f.a)^-1
    long invTerm = (f.a - 1) % mod;
    long inv = modInverse(invTerm, mod);
    long invTerm2 = (faExpN - 1) % mod;
    long mul2 = mulMod(invTerm2, inv, mod);
    long b = mulMod(f.b, mul2, mod);
    return Linear(faExpN, b);
}

long getFinal(Linear linear, long place, long mod) {
    return (mulMod(place, linear.a, mod) + linear.b) % mod;
}

long reverseShuffle(Technique[] techniques, long size, ulong cardToTrack, ulong iterations) {
    long mod = size;    
    techniques.reverse;
    Linear lin = Linear(1, 0);
    foreach(t; techniques) {
        auto l = getLinear(t, mod);
        lin = mulLinears(lin, l, mod);
    }
    lin = expLinear(lin, iterations, mod);

    auto result = lin.getFinal(cardToTrack, mod);
    if (result < 0) {
        result += mod;
    }
    return result;
}

unittest {
    {
        Technique[] techniques = [ Technique(Dealinc(7)), Technique(Dealnew()), Technique(Dealnew()), ];
        auto result = reverseShuffle(techniques, 10, 1, 1);
        io.writeln("Result = ", result);
        assert(result == 3);
    }
    {
        Technique[] techniques = [Technique(Dealnew()), 
            Technique(Cut(-2)), 
            Technique(Dealinc(7)), 
            Technique(Cut(8)), 
            Technique(Cut(-4)), 
            Technique(Dealinc(7)), 
            Technique(Cut(3)),
            Technique(Dealinc(9)), 
            Technique(Dealinc(3)), 
            Technique(Cut(-1)), ];
        auto techniqueCopy = techniques.dup;
        auto result1 = shuffle2(techniques, 10, 0, 1);
        io.writeln("Result1 = ", result1);
        auto result2 = reverseShuffle(techniqueCopy, 10, 0, 1);
        io.writeln("Result2 = ", result2);
        assert(result1 == result2);
    }
    {
        const size = 119315717514047;
        Technique[] techniques = [ 
            Technique(Dealinc(11)),
            Technique(Cut(3255)),
            Technique(Dealinc(20)), 
            Technique(Cut(-5914)), 
        ];
        auto techniqueCopy = techniques.dup;
        auto result1 = shuffle2(techniques, size, 2020, 1);
        io.writeln("----> ", result1);
        auto result2 = reverseShuffle(techniqueCopy, size, 2020, 1);
        io.writeln("----> ", result2);
        assert(result1 == result2);
    }
    {
        Technique[] techniques = [
            Technique(Cut(-2)), 
            Technique(Dealinc(7)), 
        ];
        auto techniqueCopy = techniques.dup;
        auto result1 = shuffle2(techniques, 11, 0, 2);
        io.writeln("Result1 = ", result1);
        auto result2 = reverseShuffle(techniqueCopy, 11, 0, 2);
        io.writeln("Result2 = ", result2);
        assert(result1 == result2);
    }
    {
        const size = 119315717514047;
        // const size = 9967;
        Technique[] techniques = [ 
            Technique(Dealinc(11)),
            Technique(Cut(3255)),
            Technique(Dealinc(20)), 
            Technique(Cut(-5914)), 
        ];
        auto techniqueCopy = techniques.dup;
        auto result1 = shuffle2(techniques, size, 2020, 2);
        io.writeln("----> ", result1);
        auto result2 = reverseShuffle(techniqueCopy, size, 2020, 2);
        io.writeln("----> ", result2);
        assert(result1 == result2);
    }
}

void part2(string[] lines) {
    auto techniques = lines.map!(parse).array;
    auto result = reverseShuffle(techniques, 119315717514047, 2020, 101741582076661);
    io.writeln(result);
}

void main()
{
    auto lines = io.stdin.byLineCopy.array;
    part1(lines);
    part2(lines);
}