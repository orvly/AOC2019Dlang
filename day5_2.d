module day5_2;

import std.stdio, std.algorithm, std.range, std.conv, std.array;

int main() {
    int[] a = stdin.byLineCopy.array[0].split(",").map!(to!int).array;
    auto bk = a.dup;
    bool finished = false;
    const input = 5;
    int[] outputs;
    a = bk.dup;
    int ip;

    while (a[ip] != 99 ) {
        int op = a[ip] % 100;
        int mode1 = a[ip] / 100 % 10, mode2 = a[ip] / 1000 % 10, mode3 = a[ip] / 10000 % 10;
        if (op == 1) {
            int p1 = (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            int p2 = (mode2 == 1) ? a[ip + 2] : a[a[ip + 2]];
            a[a[ip + 3]] = p1 + p2;
            ip += 4;
        } else if (op == 2) {
            int p1 = (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            int p2 = (mode2 == 1) ? a[ip + 2] : a[a[ip + 2]];
            a[a[ip + 3]] = p1 * p2;
            ip += 4;
        } else if (op == 3) {
            a[a[ip + 1]] = input;
            ip += 2;
        } else if (op == 4) {
            outputs ~= (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            ip += 2;
        } else if (op == 5) {
            int p1 = (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            int p2 = (mode2 == 1) ? a[ip + 2] : a[a[ip + 2]];
            ip = (p1 != 0) ? p2 : ip + 3;
        } else if (op == 6) {
            int p1 = (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            int p2 = (mode2 == 1) ? a[ip + 2] : a[a[ip + 2]];
            ip = (p1 == 0) ? p2 : ip + 3;
        } else if (op == 7) {
            int p1 = (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            int p2 = (mode2 == 1) ? a[ip + 2] : a[a[ip + 2]];
            a[a[ip + 3]] = (p1 < p2) ? 1 : 0;
            ip += 4;
        } else if (op == 8) {
            int p1 = (mode1 == 1) ? a[ip + 1] : a[a[ip + 1]];
            int p2 = (mode2 == 1) ? a[ip + 2] : a[a[ip + 2]];
            a[a[ip + 3]] = (p1 == p2) ? 1 : 0;
            ip += 4;
        }
    } //while

    writeln(outputs);
    return 0;
}
