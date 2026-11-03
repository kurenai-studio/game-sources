using System;
using System.Collections.Generic;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Worldgen.Mazes;

internal class WilsonMazeGenerator : IMazeGenerator
{
    public void Fill(Maze maze, Random rng)
    {
        maze.IterateEdges(maze.PlaceAt);

        int range = maze.MRange;

        var visited = new Area<bool>(range);
        var walk = new Dictionary<Vec2Int, Vec2Int>();

        visited[Vec2Int.Zero] = true;

        for (int y = -range; y <= range; y++)
        {
            for (int x = -range; x <= range; x++)
            {
                Vec2Int startPos = new(x, y);

                if (visited[startPos])
                    continue;

                walk.Clear();
                Vec2Int current = startPos;

                while (!visited[current])
                {
                    Vec2Int dir;
                    Vec2Int next;

                    do
                    {
                        dir = Vec2Int.MainDirections[rng.Next(4)];
                        next = current + dir;
                    }
                    while (next.MaxAbs > range);

                    walk[current] = dir;
                    current = next;
                }

                current = startPos;

                while (!visited[current])
                {
                    Vec2Int dir = walk[current];

                    maze.RemoveAt(current, dir);
                    visited[current] = true;

                    current += dir;
                }
            }
        }
    }
}
