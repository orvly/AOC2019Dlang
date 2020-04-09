module day16;

import io = std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.typecons;
import std.conv;
import std.math;
import std.string : splitLines;

void part1(int[] a) {
   const len = a.length;
   // io.writeln(a);
   const phases = 100;
   foreach (i; 0 .. phases) {
      int[] ptrn = [0, 1, 0, -1];
      int[] total;
      foreach (pos, digit; a) {
         int ptrni = 0;
         int[] curptrn;
         int idxn;
         while (curptrn.length < a.length + 1) {
            curptrn ~= ptrn[idxn].repeat(pos + 1).array;
            idxn = (idxn + 1) % ptrn.length.to!int;
         }
         //  io.writeln(curptrn);
         curptrn = curptrn[1 .. a.length + 1];
         //   io.writeln(curptrn);
         int sum;
         foreach (j, n; a) {
            sum += n * curptrn[j];
         }
         sum = abs(sum % 10);
         // io.writeln(sum);
         total ~= sum;

      }
      // total should now be the new a
      //a = total.to!string.map!(c => c.to!int - '0').array;
      a = total;
      if (a.length < len)
         a = 0.repeat(len - a.length).array ~ a;
      //io.writeln(a);
   }
   io.writeln(a.take(8).map!(to!string).joiner);
}

void part2(int[] a) {
   long idxOfResult = a.take(7).fold!((a, b) => a * 10 + b);
   //  auto start = (idxOfResult / 8) * 8;
   io.writeln("Index of result = ", idxOfResult);

   const repeats = 10000;
   const len = a.length * repeats;
   a = a.repeat(repeats).join.array;
   //  io.writeln(a.length);
   const phases = 100;

   auto b = new int[len];
   auto current = &a;
   auto next = &b;

   /* Following hint taken from https://dhconnelly.com/advent-of-code-2019-commentary.html#day-16

       And then it was obvious: the first n-1 elements of the nth row are zero, and 
      then the next n elements are one, and so together this means that if we’re looking 
      at a row more than half way down the matrix, the zeroes and ones make up the entire row!

      This means that we can forget about the coefficients entirely and just sum up the vector 
      elements – and if we do it starting from the last element, which is just itself, we don’t 
      even need to start the sum over at each previous element, since the sum for element 
      a[n-k] is just sum(a[n-k+1], ... a[n]).


      ME:  That's still not the whole story, since another thing is that due to the above, any number
           of last digits above the n/2 mark can be calculated independently, I saw this by printing and looking at the 
           rows of coefficients for part 1.   So an easy optimization is to calculate from the end
           only the number of digits down to the required index.
           Another thing to notice is we should still allocate a result array for each round, however
           this can be alleviated by switching between 2 buffers (double-buffer).
   */
   foreach (i; 0 .. phases) {
      long sum = 0;
      (*next)[] = 0;
      for (int pos = len - 1; pos >= idxOfResult - 1; pos--) {
         sum += (*current)[pos];
         (*next)[pos] = (abs(sum) % 10).to!int;
      }
      //   io.writeln(*next);
      auto tmp = current;
      current = next;
      next = tmp;
   }
   // io.writeln("A=\r\n", *current);
   // DLANG: Why is to!uint cast needed to compile the code below??
   auto result = (*current)[idxOfResult.to!uint .. idxOfResult.to!uint + 8];
   io.writeln(result.map!(to!string).joiner);

}

int main() {
   int partNum = 2;
   int[] a = io.stdin.byLineCopy.array[0].map!(c => c.to!int - '0').array;
   part1(a);
   part2(a);

   return 0;
}
