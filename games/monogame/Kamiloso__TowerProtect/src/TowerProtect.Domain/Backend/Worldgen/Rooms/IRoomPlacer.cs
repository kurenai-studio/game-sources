using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms;

internal interface IRoomPlacer
{
    void PlaceRooms(Area<TileType> world, Random rng);
}
