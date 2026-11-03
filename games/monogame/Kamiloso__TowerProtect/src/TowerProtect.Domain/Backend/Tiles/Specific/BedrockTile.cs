using TowerProtect.Domain.Backend.Tiles.Abstract;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Specific;

public sealed class BedrockTile : Tile
{
    private BedrockTile() : base() { }
    public static BedrockTile Instance { get; } = new();

    public override TileType Type => TileType.Bedrock;
}
