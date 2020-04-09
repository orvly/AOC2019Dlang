module day10;

import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

int main() {

  bool[int][int] map;
  auto lines = io.stdin.byLineCopy.array;
  foreach (j, line; lines) {
    foreach (i, c; line) {
      if (c == '#') {
        map.require(j.to!int).require(i.to!int, true);
      }
    }
  }
  /*
io.stdin.byLineCopy.array.each!((j, line) => 
    line.each!((i, c) { 
      if (c == '#') {
        map.require(j).require(i, true); }}));
*/
  int total = map.values
    .map!(line => line.length)
    .sum
    .to!int;
  // io.writeln(total);
  int[int][int] xyToNumSeen;

  alias Point = Tuple!(int, "x", int, "y");
  alias Vector = Tuple!(double, "angle", int, "direction");
  alias VectorToPoints = Point[][Vector];
  VectorToPoints[Point] PointsToTheirPointsOnLines;

  foreach (kv1; map.byKeyValue) {
    int y1 = kv1.key;
    foreach (int x1; kv1.value.keys) {
      // For part 1. "a" as in the coefficient of a linear equation representing line of sight.
      int[int][double] aToDirectionToNumOnLine; 
      VectorToPoints vdp;
      foreach (kv2; map.byKeyValue) {
        int y2 = kv2.key;
        foreach (int x2; kv2.value.keys) {
          if (x1 == x2 && y1 == y2)
            continue;
          // A->B  calc a,b
          // A->C  calc a,b
          // If they are the same a,b, then distance dx1 (x axis) between A,B and dx2 between A,C 
          // (unless they are on a vertical line)
          // Keep the minimum between dx's.  Compare distance to each other checked point, that has the same a,b 
          // to the minimum, replace it if it's less.
          // y1=ax1+b
          // y2=ax2+b
          // y1-y2=a(x1-x2)

          // a=y1-y2 / x1-x2
          // b=ax1-y1
          int dx = x1 - x2;
          int dy = y1 - y2;
          double a = dy.to!double / dx; // if dx==0 can be +INF or -INF
          // double b = (dx != 0) ? (a * x1 - y1) ? 0;
          int direction = (dx > 0) ? 1 : ((dx < 0) ? -1 : 0);
          // For part 1
          // Add to the number of points on the same line+heading
          aToDirectionToNumOnLine.require(a).require(direction, 0) += 1;

          // For part 2: Calculate the angle 
          auto ang = atan(a);
          if (direction == 0) {
            ang = -ang;
            direction = -1;
          }
          vdp[Vector(ang, direction)] ~= Point(y2, x2);
        } // foreach
      } // foreach
      int numHidden = aToDirectionToNumOnLine.values.map!(
          dirs => dirs.values.map!(// Number of points the same line -1 is the number that is hidden.
          pointsOnSameLine => pointsOnSameLine - 1).array.sum).sum;

      // -1 because we exclude the current point
      xyToNumSeen.require(x1).require(y1, total - numHidden - 1);
      // For part 2:
      PointsToTheirPointsOnLines[Point(x1, y1)] = vdp;
    } // foreach
  } // foreach

  auto maxSeen = 0;
  Point maxSeenPoint;
  foreach (xs; xyToNumSeen.byKeyValue) {
    foreach (ys; xs.value.byKeyValue) {
      if (ys.value > maxSeen) {
        maxSeen = ys.value;
        maxSeenPoint = Point(xs.key, ys.key);
      }
    }
  }
  auto result1 = maxSeen;
  io.writeln(result1);
  // io.writeln(maxSeenPoint);

  VectorToPoints vdp = PointsToTheirPointsOnLines[maxSeenPoint];
  // Sort points in each vector by their distance from the point
  // Then prepare an array of the vectors sorted by their angle
  foreach (points; vdp.values) {
    points.sort!((p1, p2) {
      auto dx1 = abs(p1.x - maxSeenPoint.x);
      auto dx2 = abs(p2.x - maxSeenPoint.x);
      auto dy1 = abs(p1.y - maxSeenPoint.y);
      auto dy2 = abs(p2.y - maxSeenPoint.y);
      if (dx1 == dx2)
        return dy1 < dy2;
      return dx1 < dx2;
    });
  }
  auto vectors = vdp.keys.array;
  vectors.sort!((v1, v2) {
    if (v1.direction == v2.direction)
      return v1.angle < v2.angle;
    return v1.direction < v2.direction;
  });
  // io.writeln("Vectors:");
  // foreach(v; vectors) {
  //   io.writeln(v);
  //   io.writeln(vdp[v]);
  // }

  int shot = 200 - 1;
  Point result2;
  while (shot > 0) {
    foreach (v; vectors) {
      Point[] astros = vdp[v];
      if (astros.length > 0) {
        if (shot == 0) {
          result2 = astros.front;
        }
        astros.popFront;
        shot -= 1;
      }
    }
  }
  // io.writeln(result2);
  io.writeln(result2.x * 100 + result2.y);
  return 0;
}
