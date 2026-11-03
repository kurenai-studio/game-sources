// ============================================
// PathfindingHelper.cs - Utilities for pathfinding
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.World;
using System;
using System.Collections.Generic;

namespace DungeonExplorer.AI
{
    /// <summary>
    /// Static helper methods for pathfinding operations
    /// </summary>
    public static class PathfindingHelper
    {
        /// <summary>
        /// Calculates Manhattan distance between two points
        /// </summary>
        public static float ManhattanDistance(Vector2 a, Vector2 b)
        {
            return Math.Abs(a.X - b.X) + Math.Abs(a.Y - b.Y);
        }

        /// <summary>
        /// Calculates Euclidean distance between two points
        /// </summary>
        public static float EuclideanDistance(Vector2 a, Vector2 b)
        {
            return Vector2.Distance(a, b);
        }

        /// <summary>
        /// Calculates diagonal distance (allows diagonal movement)
        /// </summary>
        public static float DiagonalDistance(Vector2 a, Vector2 b)
        {
            float dx = Math.Abs(a.X - b.X);
            float dy = Math.Abs(a.Y - b.Y);
            return Math.Max(dx, dy);
        }

        /// <summary>
        /// Gets the cardinal direction from one point to another
        /// </summary>
        public static Vector2 GetDirection(Vector2 from, Vector2 to)
        {
            var direction = to - from;
            if (direction == Vector2.Zero) return Vector2.Zero;

            direction.Normalize();
            return direction;
        }

        /// <summary>
        /// Snaps a direction vector to the nearest cardinal direction
        /// </summary>
        public static Vector2 SnapToCardinalDirection(Vector2 direction)
        {
            if (direction == Vector2.Zero) return Vector2.Zero;

            float absX = Math.Abs(direction.X);
            float absY = Math.Abs(direction.Y);

            if (absX > absY)
            {
                return new Vector2(Math.Sign(direction.X), 0);
            }
            else
            {
                return new Vector2(0, Math.Sign(direction.Y));
            }
        }

        /// <summary>
        /// Checks if a path is clear between two points using simple line-of-sight
        /// </summary>
        public static bool IsPathClear(Vector2 start, Vector2 end, Dungeon dungeon, int tileSize = 32)
        {
            var startGrid = new Vector2((int)(start.X / tileSize), (int)(start.Y / tileSize));
            var endGrid = new Vector2((int)(end.X / tileSize), (int)(end.Y / tileSize));

            var current = startGrid;
            var direction = GetDirection(startGrid, endGrid);
            var distance = Vector2.Distance(startGrid, endGrid);

            for (float t = 0; t <= distance; t += 0.5f)
            {
                var checkPos = startGrid + direction * t;
                int x = (int)Math.Round(checkPos.X);
                int y = (int)Math.Round(checkPos.Y);

                if (!dungeon.IsWalkable(x, y))
                    return false;
            }

            return true;
        }

        /// <summary>
        /// Finds the nearest walkable position to a target position
        /// </summary>
        public static Vector2? FindNearestWalkablePosition(Vector2 target, Dungeon dungeon, int maxRadius = 5, int tileSize = 32)
        {
            var gridPos = new Vector2((int)(target.X / tileSize), (int)(target.Y / tileSize));

            // Check if the target position is already walkable
            if (dungeon.IsWalkable((int)gridPos.X, (int)gridPos.Y))
                return target;

            // Spiral outward from the target position
            for (int radius = 1; radius <= maxRadius; radius++)
            {
                for (int dx = -radius; dx <= radius; dx++)
                {
                    for (int dy = -radius; dy <= radius; dy++)
                    {
                        // Only check positions on the edge of the current radius
                        if (Math.Abs(dx) != radius && Math.Abs(dy) != radius)
                            continue;

                        int x = (int)gridPos.X + dx;
                        int y = (int)gridPos.Y + dy;

                        if (dungeon.IsWalkable(x, y))
                        {
                            return new Vector2(x * tileSize + tileSize / 2f, y * tileSize + tileSize / 2f);
                        }
                    }
                }
            }

            return null; // No walkable position found within radius
        }

        /// <summary>
        /// Simplifies a path by removing redundant waypoints
        /// </summary>
        public static List<Vector2> SimplifyPath(List<Vector2> path, Dungeon dungeon, float tolerance = 2f)
        {
            if (path.Count <= 2) return new List<Vector2>(path);

            var simplified = new List<Vector2> { path[0] };

            for (int i = 1; i < path.Count - 1; i++)
            {
                var prev = simplified[simplified.Count - 1];
                var current = path[i];
                var next = path[i + 1];

                // Check if we can skip this waypoint
                if (Vector2.Distance(prev, next) <= tolerance * 2 && IsPathClear(prev, next, dungeon))
                {
                    continue; // Skip this waypoint
                }

                simplified.Add(current);
            }

            simplified.Add(path[path.Count - 1]);
            return simplified;
        }

        /// <summary>
        /// Calculates the total length of a path
        /// </summary>
        public static float CalculatePathLength(List<Vector2> path)
        {
            if (path.Count < 2) return 0f;

            float totalLength = 0f;
            for (int i = 1; i < path.Count; i++)
            {
                totalLength += Vector2.Distance(path[i - 1], path[i]);
            }

            return totalLength;
        }

        /// <summary>
        /// Gets a position along a path at a specific distance from the start
        /// </summary>
        public static Vector2 GetPositionAlongPath(List<Vector2> path, float distance)
        {
            if (path.Count == 0) return Vector2.Zero;
            if (path.Count == 1 || distance <= 0) return path[0];

            float currentDistance = 0f;

            for (int i = 1; i < path.Count; i++)
            {
                var segmentLength = Vector2.Distance(path[i - 1], path[i]);

                if (currentDistance + segmentLength >= distance)
                {
                    // The target distance is within this segment
                    float remainingDistance = distance - currentDistance;
                    float t = remainingDistance / segmentLength;
                    return Vector2.Lerp(path[i - 1], path[i], t);
                }

                currentDistance += segmentLength;
            }

            // Distance is beyond the end of the path
            return path[path.Count - 1];
        }

        /// <summary>
        /// Checks if two paths intersect
        /// </summary>
        public static bool DoPathsIntersect(List<Vector2> pathA, List<Vector2> pathB, float tolerance = 16f)
        {
            for (int i = 0; i < pathA.Count - 1; i++)
            {
                for (int j = 0; j < pathB.Count - 1; j++)
                {
                    if (DoLineSegmentsIntersect(pathA[i], pathA[i + 1], pathB[j], pathB[j + 1], tolerance))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        /// <summary>
        /// Checks if two line segments intersect within a tolerance
        /// </summary>
        private static bool DoLineSegmentsIntersect(Vector2 a1, Vector2 a2, Vector2 b1, Vector2 b2, float tolerance)
        {
            // Simple distance-based check for intersection
            var midA = (a1 + a2) * 0.5f;
            var midB = (b1 + b2) * 0.5f;
            
            return Vector2.Distance(midA, midB) <= tolerance;
        }

        /// <summary>
        /// Generates random waypoints around a central position
        /// </summary>
        public static List<Vector2> GenerateRandomWaypoints(Vector2 center, int count, float radius, Dungeon dungeon, Random random, int tileSize = 32)
        {
            var waypoints = new List<Vector2>();

            for (int i = 0; i < count * 3; i++) // Try more times than needed
            {
                if (waypoints.Count >= count) break;

                var angle = (float)(random.NextDouble() * Math.PI * 2);
                var distance = (float)(random.NextDouble() * radius);
                var position = center + new Vector2(
                    (float)Math.Cos(angle) * distance,
                    (float)Math.Sin(angle) * distance
                );

                var gridPos = new Vector2((int)(position.X / tileSize), (int)(position.Y / tileSize));
                
                if (dungeon.IsWalkable((int)gridPos.X, (int)gridPos.Y))
                {
                    waypoints.Add(position);
                }
            }

            return waypoints;
        }
    }
}