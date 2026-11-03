using System;
using System.Collections.Generic;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Model.Tiles;

public readonly record struct TilemapData(int Range, string Base64)
{
    public static TilemapData FromArea<T>(Area<T> area, Func<T, TileData> mapper)
    {
        var bytes = new List<byte>(area.Capacity * 3);

        bool hasFirst = false;
        TileData currentTile = default;
        byte count = 0;

        area.Iterate(pos =>
        {
            TileData tileData = mapper(area[pos]);

            if (!hasFirst)
            {
                currentTile = tileData;
                count = 1;
                hasFirst = true;
                return;
            }

            if (tileData == currentTile && count < byte.MaxValue)
            {
                count++;
            }
            else
            {
                bytes.Add((byte)currentTile.Type);
                bytes.Add(currentTile.Durability);
                bytes.Add(count);

                currentTile = tileData;
                count = 1;
            }
        });

        if (hasFirst)
        {
            bytes.Add((byte)currentTile.Type);
            bytes.Add(currentTile.Durability);
            bytes.Add(count);
        }

        return new TilemapData(area.Range, Convert.ToBase64String(bytes.ToArray()));
    }

    public Func<Vec2Int, TileData> GetPopulator()
    {
        Dictionary<Vec2Int, TileData> dict = new(Area.Capacity(Range));

        int ptr = 0;
        byte[] bytes = Convert.FromBase64String(Base64);

        TileData currentTile = default;
        int remainingCount = 0;

        Area.Iterate(Range, pos =>
        {
            if (remainingCount == 0)
            {
                if (ptr + 2 >= bytes.Length)
                    return;

                var tileType = (TileType)bytes[ptr++];
                byte durability = bytes[ptr++];
                remainingCount = bytes[ptr++];

                currentTile = new TileData(tileType, durability);
            }

            dict.Add(pos, currentTile);
            remainingCount--;
        });

        return pos => dict.GetValueOrDefault(pos, TileData.Air);
    }
}
