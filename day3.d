import io = std.stdio;
import std.file;
import std.algorithm;
import std.range;
import std.typecons;
import std.conv;
import std.math;
import std.string : splitLines;

int main() {
	// Sort of BUG in D: without the first ".array" below, the (internal) 
	// array is consumed the first time we iterate over it (e.g. print it).
	auto a = io.stdin.byLineCopy.array.map!
		(l => l.split(",").map!(
		d => tuple(d[0], d[1..$].to!int)).array).array;

	//io.writeln(a[0]);

	int[2][2] p;// p1x,p1y,p2x,p2y;
	int[2] steps = [0,0];
	int[int][int] map;
	int[] dist;
	int[2][int][int] stepsmap; // For part 2
	int[] intersecTotalSteps;
	void update(int x,int y, size_t j) {
		int i = j.to!int + 1;
		// For both parts - identify an intersection
		bool xexists =((x in map) !is null);
		bool exists = 
			xexists && 
			((y in map[x]) !is null) && 
			(map[x][y] ^ i) !=0;
		// For part 2
		if (x != 0 || y != 0)
			steps[j]++;
		// For part 2
		stepsmap.require(x, (int[2][int]).init)
			.require(y, (int[2]).init)[j] = steps[j];
		if (exists && x != 0 && y != 0) {
			// For part 1
			dist~=abs(x)+abs(y); 
			// For part 2
			// For the second wire, then if we have an intersection, save 
			// total number of steps
			intersecTotalSteps ~= (stepsmap[x][y]).array.sum;
		}
		// For both parts: if this is the second wire, set a bit 
		// to mark we were there so we'll be able to both identify crossing
		// ourselves or an intersection.
		if (xexists) // If the first key doesn't exist, we can't do |=
		map[x][y] |=i;
		else map[x][y]=i;
	}
	a.each!((i, inst) => inst.each!( (t) {

		if (t[0] == 'D') {  iota(t[1]).each!((n) { 
			update(p[i][0], p[i][1], i);
			p[i][1]++; 
		});} 

		if (t[0] == 'U') {  iota(t[1]).each!((n) { 
			update(p[i][0], p[i][1], i);
			p[i][1]--; 
		});}

		if (t[0] == 'R') {  iota(t[1]).each!((n) { 
			update(p[i][0], p[i][1], i);
			p[i][0]++; 
		});}

		if (t[0] == 'L') {  iota(t[1]).each!((n) { 
			update(p[i][0], p[i][1], i);
			p[i][0]--; 
		});}

	}));
	auto result=dist.minElement;
	io.writeln(result);
	// Part 2
	io.writeln(intersecTotalSteps.minElement);
	return 0;
}