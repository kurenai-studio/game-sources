using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Helpers;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Specific;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Specific.Blob;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Specific.Farm;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;
using static TowerProtect.Domain.Config.WorldgenConfig;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms;

internal class DefaultRoomPlacer : IRoomPlacer
{
    private const double RoomPeriod = CellSize + 1;

    public void PlaceRooms(Area<TileType> world, Random rng)
    {
        var worldArea = new RoomPlacingArea(world);

        worldArea.Iterate(pos =>
        {
            if (pos.MaxAbs <= 1)
            {
                if (pos == Vec2Int.Zero)
                    PlaceSpawnRoom(worldArea, pos, rng);
            }
            else
            {
                if (pos.x % RoomPeriod == 0 && pos.y % RoomPeriod == 0)
                    TryPlaceAt(worldArea, pos, rng);
            }
        });
    }

    private static void PlaceSpawnRoom(RoomPlacingArea worldArea, Vec2Int pos, Random rng)
    {
        new SpawnRoom(rng).PlaceInWorld(worldArea, pos);
    }

    private static void TryPlaceAt(RoomPlacingArea worldArea, Vec2Int pos, Random rng)
    {
        ChanceProbe probe = new(rng);

        probe.If(0.08, () => new RockRoom(rng).PlaceInWorld(worldArea, pos));
        probe.If(0.08, () => new LakeRoom(rng).PlaceInWorld(worldArea, pos));

        if (worldArea.IsDeadEnd(pos, out int rots))
        {
            probe.If(0.08, () => new MonsterRoom(rng).PlaceInWorld(worldArea, pos, rots));
        }

        if (worldArea.IsCorridor(pos, out rots))
        {
            probe.If(0.08, () => new FruitRoom(rng).PlaceInWorld(worldArea, pos, rots));
        }
    }
}
