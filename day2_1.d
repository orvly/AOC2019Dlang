module day2_1;

import std.stdio, std.algorithm, std.range, std.conv, std.array;

int main()
{

    auto a = stdin.byLineCopy.array[0].split(",").map!(to!int).array;
    a[1] = 12;
    a[2] = 2;
    int ip;
    while (a[ip] != 99)
    {
        if (a[ip] == 1)
        {
            a[a[ip + 3]] = a[a[ip + 1]] + a[a[ip + 2]];
        }
        else if (a[ip] == 2)
        {
            a[a[ip + 3]] = a[a[ip + 1]] * a[a[ip + 2]];
        }
        ip += 4;
    }

    writeln(a[0]);
    return 0;
}