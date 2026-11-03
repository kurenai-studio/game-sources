using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Specific;

public sealed class AirTile : Tile
{
    private AirTile() : base() { }
    public static AirTile Instance { get; } = new();

    public override TileType Type => TileType.Air;
    public override bool IsPassable => true;
}
