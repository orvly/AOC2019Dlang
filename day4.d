import io = std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.typecons;
import std.conv;
import std.math;
import std.string : splitLines;

int main() {

  int x1 = 240298;
  int x2 = 784956;
  long count, count2;
  foreach (x; x1 .. x2 + 1) {
    auto s = x.to!string;
    bool hasdouble = false, isinc = true;
    int groupsize = 1;
    dchar prev;
    bool hasgroupof2;
    foreach (i, c; s) {
      if (!hasdouble && i > 0)
        hasdouble = c == s[i - 1];

      if (i > 0)
        isinc = isinc && c >= s[i - 1];
      if (i == 0)
        prev = c;
      else if (c == prev) {
        ++groupsize;
      } else {
        prev = c;
        hasgroupof2 |= groupsize == 2;
        groupsize = 1;
      }
    }
    if (hasdouble && isinc) {
      count++;
      hasgroupof2 |= groupsize == 2;
      if (hasgroupof2)
        count2++;
    }
  }
  io.writeln(count);
  io.writeln(count2);
  return 0;
}
