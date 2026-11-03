// ============================================
// AStar.cs - A* Pathfinding implementation
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.World;
using System;
using System.Collections.Generic;
using System.Linq;

namespace DungeonExplorer.AI
{
    /// <summary>
    /// A* pathfinding algorithm implementation
    /// </summary>
    public class AStar
    {
        private readonly int TILE_SIZE = 32;

        /// <summary>
        /// Finds the shortest path between two world positions
        /// </summary>
        public List<Vector2> FindPath(Vector2 startWorld, Vector2 endWorld, Dungeon dungeon)
        {
            // Convert world coordinates to grid coordinates
            var start = WorldToGrid(startWorld);
            var end = WorldToGrid(endWorld);

            return FindPathGrid(start, end, dungeon);
        }

        /// <summary>
        /// Finds the shortest path between two grid positions
        /// </summary>
        public List<Vector2> FindPathGrid(Vector2 start, Vector2 end, Dungeon dungeon)
        {
            var startNode = new Node((int)start.X, (int)start.Y);
            var endNode = new Node((int)end.X, (int)end.Y);

            // Check if start and end positions are valid
            if (!dungeon.IsWalkable(startNode.X, startNode.Y) || !dungeon.IsWalkable(endNode.X, endNode.Y))
            {
                return new List<Vector2>();
            }

            var openSet = new List<Node> { startNode };
            var closedSet = new HashSet<Node>();
            var cameFrom = new Dictionary<Node, Node>();

            startNode.GCost = 0;
            startNode.HCost = GetDistance(startNode, endNode);

            while (openSet.Count > 0)
            {
                // Get node with lowest F cost
                var currentNode = openSet.OrderBy(n => n.FCost).ThenBy(n => n.HCost).First();

                openSet.Remove(currentNode);
                closedSet.Add(currentNode);

                // Check if we reached the destination
                if (currentNode.Equals(endNode))
                {
                    return ReconstructPath(cameFrom, currentNode, dungeon);
                }

                // Check all neighbors
                foreach (var neighbor in GetNeighbors(currentNode, dungeon))
                {
                    if (closedSet.Contains(neighbor))
                        continue;

                    var tentativeGCost = currentNode.GCost + GetDistance(currentNode, neighbor);

                    if (!openSet.Contains(neighbor))
                    {
                        openSet.Add(neighbor);
                    }
                    else if (tentativeGCost >= neighbor.GCost)
                    {
                        continue;
                    }

                    cameFrom[neighbor] = currentNode;
                    neighbor.GCost = tentativeGCost;
                    neighbor.HCost = GetDistance(neighbor, endNode);
                }
            }

            // No path found
            return new List<Vector2>();
        }

        private List<Node> GetNeighbors(Node node, Dungeon dungeon)
        {
            var neighbors = new List<Node>();
            var directions = new[]
            {
                new Vector2(0, -1), // Up
                new Vector2(1, 0), // Right
                new Vector2(0, 1), // Down
                new Vector2(-1, 0) // Left
            };

            foreach (var direction in directions)
            {
                int x = node.X + (int)direction.X;
                int y = node.Y + (int)direction.Y;

                if (dungeon.IsWalkable(x, y))
                {
                    neighbors.Add(new Node(x, y));
                }
            }

            return neighbors;
        }

        private float GetDistance(Node nodeA, Node nodeB)
        {
            int distX = Math.Abs(nodeA.X - nodeB.X);
            int distY = Math.Abs(nodeA.Y - nodeB.Y);

            // Manhattan distance (since we only allow 4-directional movement)
            return distX + distY;
        }

        private List<Vector2> ReconstructPath(Dictionary<Node, Node> cameFrom, Node endNode, Dungeon dungeon)
        {
            var path = new List<Vector2>();
            var currentNode = endNode;

            while (cameFrom.ContainsKey(currentNode))
            {
                // Convert back to world coordinates
                path.Add(GridToWorld(currentNode.X, currentNode.Y));
                currentNode = cameFrom[currentNode];
            }

            // Add the start position
            path.Add(GridToWorld(currentNode.X, currentNode.Y));

            // Reverse to get path from start to end
            path.Reverse();
            return path;
        }

        private Vector2 WorldToGrid(Vector2 worldPosition)
        {
            return new Vector2(
                (int)Math.Floor(worldPosition.X / TILE_SIZE),
                (int)Math.Floor(worldPosition.Y / TILE_SIZE)
            );
        }

        private Vector2 GridToWorld(int gridX, int gridY)
        {
            return new Vector2(
                gridX * TILE_SIZE + TILE_SIZE / 2f,
                gridY * TILE_SIZE + TILE_SIZE / 2f
            );
        }
    }
}