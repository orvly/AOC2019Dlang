# [DLang](https://dlang.org/) (D Programming Language) Solutions for [Advent of Code 2019](https://adventofcode.com/2019)

This repo contains my solutions to the Advent of Code 2019 puzzles.
I solved them all using the D programming language, mainly because I wanted to learn it.  This was also the first time I tried doing Advent of Code.

I formatted and cleaned up all the solutions, and added some more comments.

All solutions are self contained, mainly because I wrote about half of them on my cell phone, online, on the bus, while commuting to work :-)

My "commute setup":
* The [ideone](https://ideone.com) website, which is very mobile friendly as opposed to most other "online IDEs" out there, and it supports dlang.  

However all the code must be self contained there.

In order to achieve this:
- I didn't use **any** external packages.
- I didn't use dub.
- I copied my IntCode implementation from solution to solution.
- The input is always read from stdin (except from day 25). Online IDEs cannot read from local files, but can accept input from stdin.
- I used rdmd exclusively

This makes it trivial to run all of my solutions online against any of the puzzle inputs, in any of the online "IDEs" which accept support the D language (almost all of the major ones).

Using rdmd and not using dub also had the added benefit of faster time to compilation and provided faster iteration times. For some reason dub was too slow on my system, even if no packges at all were used.

My home setup:
* VS Code
* The code-d extension.  
* I wrote a small task to run rdmd with the default input file (in the .vscode/tasks.json file in this repo). It assumes the input file is called the same as the source file but with a "_input" suffix.

I used associative arrays almost exclusively instead of matrices for 2d arrays. This had a negligble in terms of performance and helped somewhat in puzzles where we don't know the extent of the area around us.

I added some specific comments about difficulties I had with the D language to the code, marked them with DLANG.  I haven't run into outright bugs, but some compiler error messages were often misleading.
