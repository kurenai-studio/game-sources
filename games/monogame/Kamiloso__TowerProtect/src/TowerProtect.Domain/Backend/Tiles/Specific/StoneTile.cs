using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Specific;

public sealed class WallTile : Tile
{
    private WallTile() : base() { }
    public static WallTile Instance { get; } = new();

    public override TileType Type => TileType.Wall;
}
