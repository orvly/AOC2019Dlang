module day12;

import io = std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.typecons;
import std.conv;
import std.math;
import std.string : splitLines;

T[][] combs(T)(in T[] arr, in int k) pure nothrow {
    if (k == 0)
        return [[]];
    typeof(return) result;
    foreach (immutable i, immutable x; arr)
        foreach (suffix; arr[i + 1 .. $].combs(k - 1))
            result ~= x ~ suffix;
    return result;
}

T lcm(T)(T m, T n) {
    import std.numeric : gcd;

    if (m == 0)
        return m;
    if (n == 0)
        return n;
    return abs((m * n) / gcd(m, n));
}

alias P = Tuple!(long, "x", long, "y", long, "z");

void step(P[] pos, P[] vel, const int[][] combs) {
    foreach (comb; combs) {
        if (pos[comb[0]].x != pos[comb[1]].x) {
            vel[comb[0]].x += (pos[comb[0]].x < pos[comb[1]].x) ? 1 : -1;
            vel[comb[1]].x += (pos[comb[0]].x > pos[comb[1]].x) ? 1 : -1;
        }
        if (pos[comb[0]].y != pos[comb[1]].y) {
            vel[comb[0]].y += (pos[comb[0]].y < pos[comb[1]].y) ? 1 : -1;
            vel[comb[1]].y += (pos[comb[0]].y > pos[comb[1]].y) ? 1 : -1;
        }
        if (pos[comb[0]].z != pos[comb[1]].z) {
            vel[comb[0]].z += (pos[comb[0]].z < pos[comb[1]].z) ? 1 : -1;
            vel[comb[1]].z += (pos[comb[0]].z > pos[comb[1]].z) ? 1 : -1;
        }
    }
    foreach (i, ref p; pos) {
        p.x += vel[i].x;
        p.y += vel[i].y;
        p.z += vel[i].z;
    }
}

int main() {
    // <x=-1, y=0, z=2>

    P[] origPos = io.stdin
        .byLineCopy
        .array
        .map!(s => s[1 .. $ - 1].split(",").map!(s2 => s2.split("=")[1].to!long).array)
        .map!(ar => P(ar[0], ar[1], ar[2]))
        .array;
    // io.writeln(pos);
    auto pos = origPos.dup;
    const num = pos.length;
    auto vel = new P[num];
    const combsSeed = iota(num).map!(to!int).array;
    const allCombs = combs(combsSeed, 2);

    // Part 1
    const steps = 1000;
    foreach (_; 0 .. steps) {
        step(pos, vel, allCombs);
    }
    auto total = pos.enumerate.map!(p => (p.value.x.abs + p.value.y.abs + p.value.z.abs) * (
            vel[p.index].x.abs + vel[p.index].y.abs + vel[p.index].z.abs)).sum;
    io.writeln(total);

    // Part 2
    // THE IDEA:  X, Y and Z (velocities and locations) are changed independently of each other,
    // so it's enough to find after how many cycles X is repeating (goes back to beginning), same for Y and Z,
    // and when we know the 3 of them, calculate the Least Common Multiple (LCM) of the three cycles.

    pos = origPos.dup;
    vel[0 .. $] = P.init;

    auto xs0 = origPos.map!(p => p.x).array;
    auto vxs0 = vel.map!(v => v.x).array;
    auto ys0 = origPos.map!(p => p.y).array;
    auto vys0 = vel.map!(v => v.y).array;
    auto zs0 = origPos.map!(p => p.z).array;
    auto vzs0 = vel.map!(v => v.z).array;

    auto xs = new long[pos.length];
    auto vxs = new long[pos.length];
    auto ys = new long[pos.length];
    auto vys = new long[pos.length];
    auto zs = new long[pos.length];
    auto vzs = new long[pos.length];

    bool[3] found = [false, false, false];
    ulong steps2 = 800000000;
    ulong xCycle, yCycle, zCycle;
    foreach (ulong stepNum; 0 .. steps2) {
        step(pos, vel, allCombs);

        pos.each!((i, p) { xs[i] = p.x; ys[i] = p.y; zs[i] = p.z; });
        vel.each!((i, p) { vxs[i] = p.x; vys[i] = p.y; vzs[i] = p.z; });
        if (xs == xs0 && vxs == vxs0 && !found[0]) {
            xCycle = stepNum + 1;
            io.writeln("Found both x: ", stepNum);
            found[0] = true;
            if (found[1] && found[2])
                break;
        }
        if (ys == ys0 && vys == vys0 && !found[1]) {
            yCycle = stepNum + 1;
            io.writeln("Found both y: ", stepNum);
            found[1] = true;
            if (found[0] && found[2])
                break;
        }
        if (zs == zs0 && vzs == vzs0 && !found[2]) {
            zCycle = stepNum + 1;
            io.writeln("Found both z: ", stepNum);
            found[2] = true;
            if (found[0] && found[1])
                break;
        }
    }
    ulong lcm1 = lcm(xCycle, yCycle);
    auto lcm2 = lcm(lcm1, zCycle);
    io.writeln("lcm = ", lcm2);

    return 0;
}
