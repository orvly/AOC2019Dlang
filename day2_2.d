import std.stdio, std.algorithm, std.range, std.conv, std.array;

int main()
{
    int[] a = stdin.byLineCopy.array[0].split(",").map!(to!int).array;
    auto bk = a.dup;
    bool finished = false;
    int noun, verb;
    foreach (i; 1..a.length)
    {
        foreach (j; 1..a.length)
        {
            a = bk.dup;
            a[1] = i.to!int;
            a[2] = j.to!int;
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
            finished = (a[0] == 19690720);
            if (finished)
            {
                noun = i.to!int;
                verb = j.to!int;
                break;
            }
        }
        if (finished)
            break;
    }
    writeln(100 * noun + verb);
    return 0;
}