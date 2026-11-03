using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Specific;

public sealed class RockTile : Tile
{
    private RockTile() : base(durability: 30) { }
    public static RockTile Create() => new();

    public override TileType Type => TileType.Rock;
    public override bool IsBreakable => true;
}
