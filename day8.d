module day8;

import io = std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.typecons;
import std.conv;
import std.math;
import std.string : splitLines;

int main() {
    const width = 25, height = 6;
    //const width = 2, height = 2;
    const picsize = width * height;
    auto raw = io.stdin.byLineCopy.array.map!((l) => iota(0, l.length, picsize)
            .map!(i => l[i .. i + picsize].array)).array;
    auto a = raw[0];
    // Why doesn't the following work for count() ?
    //foreach(img; a) { io.writeln(img.count!(c => c=='0')); }
    const minimg = a.minElement!(img => img.count!(c => c == '0'));
    const result1 = minimg.count!(c => c == '2') * minimg.count!(c => c == '1');
    io.writeln(result1);
    // Part 2
    const indices = iota(0, picsize).map!(i => a.map!(img => img[i])
            .countUntil!(c => c != '2')).array;
    const result2 = iota(0, picsize).map!(i => a[indices[i]][i]).array;
    iota(0, picsize, width).each!(
            r => io.writeln(result2[r .. r + width].map!(c => c == '0' ? ' ' : 'x')));
    // io.writeln(result2);
    return 0;
}
