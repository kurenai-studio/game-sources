using System;
using TowerProtect.Domain.Rendering.Model;

namespace TowerProtect.Domain.Model.Tiles;

public enum TileType : byte
{
    Air = default,
    Wall = 1,
    Water = 2,
    Rock = 3,
    Spawner = 4,
    Bedrock = 5,

    // Spawn markers
    AnimalMarker = 101,
    MonsterMarker = 102,
}

public static class TileTypeExtensions
{
    public static string GetTextureName(this TileType self)
        => !IsMarker(self) && Enum.GetName(self) is { } name ? name : Assets.Unknown;

    public static bool IsSolid(this TileType self)
        => self is TileType.Wall or TileType.Bedrock;

    public static bool IsUnsolid(this TileType self)
        => self is TileType.Rock or TileType.Spawner;

    public static bool IsFluid(this TileType self)
        => self is TileType.Air or TileType.Water;

    public static bool IsInvisible(this TileType self)
        => self is TileType.Air;

    public static bool IsContoured(this TileType self)
        => self.GetContourLevel() > 0;

    public static bool IsMarker(this TileType self)
        => Enum.GetName(self)?.StartsWith("Marker") ?? false;

    public static Layer GetDisplayLayer(this TileType self) => 0 switch
    {
        _ when self.IsSolid() => Layer.Solid,
        _ when self.IsUnsolid() => Layer.Unsolid,
        _ when self.IsFluid() => Layer.Fluid,
        _ => Layer.Default
    };

    public static int GetContourLevel(this TileType self) => 0 switch
    {
        _ when self.IsSolid() => 2,
        _ when self.IsUnsolid() || self is TileType.Air => 1,
        _ => 0
    };
}
