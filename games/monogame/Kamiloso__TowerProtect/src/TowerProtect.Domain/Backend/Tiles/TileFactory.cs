using AutoInterfaceAttributes;
using System;
using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Backend.Tiles.Specific;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles;

[AutoInterface]
internal class TileFactory : ITileFactory
{
    public Tile CreateTile(TileType tileType) => tileType switch
    {
        TileType.Air => AirTile.Instance,
        TileType.Wall => WallTile.Instance,
        TileType.Spawner => SpawnerTile.Create(),
        TileType.Water => WaterTile.Instance,
        TileType.Bedrock => BedrockTile.Instance,
        TileType.Rock => RockTile.Create(),
        _ => throw new InvalidOperationException($"Invalid tile type: {tileType}")
    };
}
