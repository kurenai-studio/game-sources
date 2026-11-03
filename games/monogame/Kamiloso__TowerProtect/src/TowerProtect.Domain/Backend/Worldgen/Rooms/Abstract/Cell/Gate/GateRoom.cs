using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell.Gate;

internal abstract class GateRoom(Random rng, string pattern,
    char? gate = '#',
    char? entrance = null)
    : CellRoom(rng, pattern)
{
    public override void PlaceInWorld(Area<TileType> world, Vec2Int pos, int rots = 0)
    {
        base.PlaceInWorld(world, pos, rots);

        Area.Iterate(Range + 1, rPos =>
        {
            if (Area.ContainsKey(Range, rPos))
                return;

            Vec2Int tilePos = pos + rPos;

            if (world[tilePos] == TileType.Wall)
                return;

            if (rPos.MinAbs > 1)
            {
                if (gate.HasValue)
                    world[tilePos] = ParseTile(gate.Value);
            }
            else
            {
                if (entrance.HasValue)
                    world[tilePos] = ParseTile(entrance.Value);
            }
        });
    }
}
