using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;
using static TowerProtect.Domain.Config.WorldgenConfig;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Helpers;

internal class RoomPlacingArea(Area<TileType> world)
{
    public Area<TileType> World => world;

    public void Iterate(Action<Vec2Int> action)
    {
        world.Iterate(action);
    }

    public bool IsDeadEnd(Vec2Int pos, out int rots)
    {
        int flags = (IsOpen(pos, Vec2Int.Up) ? 1 : 0)
                  | (IsOpen(pos, Vec2Int.Left) ? 2 : 0)
                  | (IsOpen(pos, Vec2Int.Down) ? 4 : 0)
                  | (IsOpen(pos, Vec2Int.Right) ? 8 : 0);

        if (int.PopCount(flags) == 1)
        {
            rots = int.TrailingZeroCount(flags);
            return true;
        }

        rots = 0;
        return false;
    }

    public bool IsCorridor(Vec2Int pos, out int rots)
    {
        int flags = (IsOpen(pos, Vec2Int.Up) ? 1 : 0)
                  | (IsOpen(pos, Vec2Int.Left) ? 2 : 0)
                  | (IsOpen(pos, Vec2Int.Down) ? 4 : 0)
                  | (IsOpen(pos, Vec2Int.Right) ? 8 : 0);

        if (flags is 5 or 10)
        {
            rots = flags == 10 ? 1 : 0;
            return true;
        }

        rots = 0;
        return false;
    }

    private bool IsOpen(Vec2Int pos, Vec2Int dir)
        => world[pos + (CellRange + 1) * dir] != TileType.Wall;

    public static implicit operator Area<TileType>(RoomPlacingArea area) => area.World;
}
