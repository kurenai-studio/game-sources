// ============================================
// Node.cs - Pathfinding node for A* algorithm
// ============================================
using System;

namespace DungeonExplorer.AI
{
    /// <summary>
    /// Represents a node in the pathfinding grid
    /// </summary>
    public class Node : IEquatable<Node>
    {
        public int X { get; set; }
        public int Y { get; set; }
        public float GCost { get; set; } // Distance from start
        public float HCost { get; set; } // Distance to end (heuristic)
        public float FCost => GCost + HCost; // Total cost

        public Node(int x, int y)
        {
            X = x;
            Y = y;
            GCost = float.MaxValue;
            HCost = 0;
        }

        public bool Equals(Node other)
        {
            if (other == null) return false;
            return X == other.X && Y == other.Y;
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as Node);
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(X, Y);
        }

        public override string ToString()
        {
            return $"Node({X}, {Y}) - F:{FCost:F1} G:{GCost:F1} H:{HCost:F1}";
        }
    }
}