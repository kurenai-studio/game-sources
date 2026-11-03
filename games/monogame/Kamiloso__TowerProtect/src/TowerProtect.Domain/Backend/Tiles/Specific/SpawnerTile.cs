using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Specific;

public sealed class SpawnerTile : Tile
{
    private SpawnerTile() : base() { }
    public static SpawnerTile Create() => new();

    public override TileType Type => TileType.Spawner;
}
