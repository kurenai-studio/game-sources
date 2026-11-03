using System;
using TowerProtect.Domain.Backend.Worldgen.Mazes;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;
using static TowerProtect.Domain.Config.WorldgenConfig;

namespace TowerProtect.Domain.Backend.Worldgen.Extended;

internal class MapMaze(int mRange) : Maze(mRange)
{
    public void Generate(IMazeGenerator generator, Random rng)
    {
        generator.Fill(this, rng);
    }

    public void Decay(double rate, Random rng)
    {
        IterateEdges((mPos, dir) =>
        {
            if (!OutlineAt(mPos, dir) && rng.NextDouble() < rate)
            {
                RemoveAt(mPos, dir);
            }
        });
    }

    public void Evaporate3x3(Vec2Int mPos)
    {
        for (int i = -1; i <= 1; i++)
        {
            RemoveAt(mPos + i * Vec2Int.Right, Vec2Int.Up);
            RemoveAt(mPos + i * Vec2Int.Right, Vec2Int.Down);
            RemoveAt(mPos + i * Vec2Int.Down, Vec2Int.Left);
            RemoveAt(mPos + i * Vec2Int.Down, Vec2Int.Right);
        }
    }

    public void CopyIntoArea(Area<TileType> area, TileType solid)
    {
        IterateEdges((mPos, dir) =>
        {
            if (!ExistsAt(mPos, dir))
                return;

            Vec2Int cellCenter = mPos * (CellSize + 1);
            Vec2Int edgeCenter = cellCenter + dir * (CellRange + 1);

            for (int i = -CellRange; i <= CellRange; i++)
            {
                Vec2Int edgePos = edgeCenter + dir.Orthogonal * i;
                area[edgePos] = solid;
            }
        });

        IterateCorners((mPos, dir) =>
        {
            if (!ExistsAt(mPos, dir))
                return;

            Vec2Int cellCenter = mPos * (CellSize + 1);
            Vec2Int cornerPos = cellCenter + dir * (CellRange + 1);

            area[cornerPos] = solid;
        });
    }
}
