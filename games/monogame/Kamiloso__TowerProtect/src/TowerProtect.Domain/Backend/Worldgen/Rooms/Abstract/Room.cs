using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract;

internal abstract class Room
{
    public int Range { get; }
    public int Size => Range * 2 + 1;
    public int Capacity => Size * Size;

    protected virtual bool RotateFreely => false;
    protected Area<TileType> RoomArea { get; }

    public Room(Random rng, int range, string pattern)
    {
        Range = range;

        string[] array = pattern.Split([' ', '\r', '\n', '\t'], StringSplitOptions.RemoveEmptyEntries);

        if (array.Length != Capacity)
            throw new InvalidOperationException($"Wrong number of tiles: {array.Length} (expected {Capacity})");

        int rots = RotateFreely ? rng.Next(4) : 0;

        RoomArea = new Area<TileType>(Range)
            .Populate(rPos =>
            {
                rPos = rPos.Rot90(rots);
                int index = (rPos.y + Range) * Size + (rPos.x + Range);
                return ParseTile(array[index][0]);
            });
    }

    protected virtual TileType ParseTile(char c) => c switch
    {
        '.' => TileType.Air,
        '#' => TileType.Wall,
        '~' => TileType.Water,
        'R' => TileType.Rock,
        'S' => TileType.Spawner,
        'B' => TileType.Bedrock,
        _ => throw new ArgumentException($"Invalid tile type: {c}")
    };

    public virtual void PlaceInWorld(Area<TileType> world, Vec2Int pos, int rots = 0)
    {
        RoomArea.Iterate(rPos => world[pos + rPos.Rot90(-rots)] = RoomArea[rPos]);
    }
}
