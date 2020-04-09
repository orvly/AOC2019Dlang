module day14;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;
import std.array : byPair;

alias Cost = Tuple!(string, "name", uint, "cost");
alias Depends = Tuple!(Cost, "material", Cost[], "inputs");
Cost toCost(string s) {
    auto parts = s.split;
    return Cost(parts[1].to!string, parts[0].to!uint);
}

void traverse2(Depends[string] costs, ulong[string] spares, ref ulong result,
        string material, ulong totalCost) {
    if (material == "ORE") {
        result += totalCost;
        return;
    }

    auto spare = material in spares;
    if (spare !is null) {
        if (*spare >= totalCost) {
            spares[material] -= totalCost;
            return;
        } else {
            totalCost -= *spare;
            spares[material] = 0;
        }
    }

    auto reaction = costs[material];
    auto prod = (totalCost.to!double / reaction.material.cost).ceil.to!ulong;
    foreach (i; reaction.inputs) {
        traverse2(costs, spares, result, i.name, i.cost * prod);
    }
    if (reaction.material.cost * prod > totalCost) {
        spares[reaction.material.name] += reaction.material.cost * prod - totalCost;
    }
}

void main() {
    Depends[string] costs;
    /* 4 C, 1 A => 1 CA*/
    auto codes = io.stdin
        .byLineCopy
        .array
        .map!(l => l.split(" => "))
        .map!(parts => tuple(parts[1].toCost.name, Depends(parts[1].toCost,
                parts[0].split(", ").map!toCost.array)));
    costs = codes.assocArray;
    auto leaves = costs.byPair.filter!(kv => kv.value.inputs[0].name == "ORE").assocArray;

    // io.writeln(leaves);
    uint[string] leavesCost;
    ulong[string] spares;
    leaves.keys.each!(l => leavesCost[l] = 0);
    costs.keys.each!(l => spares[l] = 0);
    ulong result1;
    traverse2(costs, spares, result1, "FUEL", 1);
    io.writeln(result1);

    // Find out which FUEL will give us 1000000000000 ore.
    // We know 1 FUEL requires "result1" ORE
    // Start with different amounts of FUEL until we get to trillion ORE
    // Find out upper bound
    bool foundMax;
    ulong startFuel = 1000;
    ulong oreOut;
    const trillion = 1000000000000;
    while (!foundMax) {
        traverse2(costs, spares, oreOut, "FUEL", startFuel);
        foundMax = oreOut >= trillion;
        startFuel *= 10; // Just some random factor
    }
    startFuel /= 10;
    // io.writeln(startFuel, " ", oreOut);

    // Now use binary search between startFuel and startFuel/10 to hone
    // into the exact amount.
    auto max = startFuel;
    auto min = startFuel / 10;
    bool foundExact;
    oreOut = 0;
    traverse2(costs, spares, oreOut, "FUEL", min);

    ulong curFuel;
    while (!foundExact) {
        curFuel = min + (max - min) / 2;
        // io.writeln(min, "..", max, " cur=", curFuel);
        oreOut = 0;
        traverse2(costs, spares, oreOut, "FUEL", curFuel);
        // io.writeln("ORE OUT=", oreOut, " ", oreOut > trillion);
        if (oreOut > trillion) {
            max = curFuel;
        } else if (oreOut < trillion) {
            if (curFuel == min)
                break;
            min = curFuel;
        } else {
            min = curFuel;
            break;
        }
        foundExact = (min > max);
    }
    io.writeln(curFuel - 1);
}
