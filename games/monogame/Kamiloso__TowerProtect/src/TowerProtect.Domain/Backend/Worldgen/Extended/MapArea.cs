using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Worldgen.Extended;

internal class MapArea(int range) : Area<TileType>(range)
{
    public void SpreadTile(TileType tile, double rate, Random rng)
    {
        Iterate(pos =>
        {
            if (this[pos] == TileType.Air)
            {
                if (rng.NextDouble() < rate)
                    this[pos] = tile;
            }
        });
    }

    public void PlaceRooms(IRoomPlacer roomPlacer, Random rng)
    {
        roomPlacer.PlaceRooms(this, rng);
    }
}
