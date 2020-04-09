import io = std.stdio, std.file, std.algorithm, std.range, std.typecons;
import std.conv, std.math, std.string : splitLines;

class Node {
    string s;
    bool visited;
    int depth;
    Node parent;
    Node[] children;
    this(string s1) { s = s1; }
}

int main()
{
    Node root;
    Node[string] nodes;

    io.stdin.byLineCopy.array.map!(l => l.split(")"))
        .each!( (conn) {
            auto n1 = nodes.require(conn[0], new Node(conn[0]));
            auto n2 = nodes.require(conn[1], new Node(conn[1]));
            n1.children ~= n2;
            n2.parent = n1;
            if (conn[0] == "COM") 
                root = n1;
        });

    int[] conOfSubTrees;
    
    void traversePart1(Node node, int depth) {
        node.depth = depth;
        if (node.children.length == 0) {
            Node p = node.parent;
            while(!p.visited && p.parent !is null) {
                p.visited = true;
                p = p.parent;
            }
            auto ourDepth = node.depth;
            auto parentDepth = p.depth;
            conOfSubTrees ~= (ourDepth * (ourDepth + 1) /2) - (parentDepth * (parentDepth + 1) /2);
        }
        node.children.each!(c => traversePart1(c, depth + 1));
    }
    traversePart1(root, 0);
    io.writeln(conOfSubTrees.sum);
    
    // PART 2
    Node you = nodes["YOU"];
    Node san = nodes["SAN"];
    nodes.byValue.each!( (n) => n.visited = false);
    Node traversePart2(Node node) {
        if (node is null) return null;
        if (node.visited) return node;
        node.visited = true;
        return traversePart2(node.parent);
    }
    traversePart2(you);
    Node commonParent = traversePart2(san);
    auto result = (san.depth - commonParent.depth - 1) + (you.depth - commonParent.depth - 1);
    io.writeln(result);
    return 0;
}
	
