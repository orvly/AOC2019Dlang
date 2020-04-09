module day1_2;

import std.stdio, std.algorithm, std.range, std.conv;
int calc(int f) { 
    auto r=f/3-2;
    if (r>0) return r+calc (r);
    return 0;
}
int main() {
    auto result =stdin 
        .byLineCopy() // copying each line
        .array().map!(to!int).map!(calc)
        .sum;
    writeln(result);
    return 0;
}