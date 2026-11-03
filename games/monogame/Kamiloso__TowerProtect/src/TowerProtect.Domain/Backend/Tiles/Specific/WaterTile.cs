using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Specific;

public sealed class WaterTile : Tile
{
    private WaterTile() : base() { }
    public static WaterTile Instance { get; } = new();

    public override TileType Type => TileType.Water;
}
