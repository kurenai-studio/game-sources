using System;

namespace TowerProtect.Domain.Client.Tiles.Model;

[Flags]
public enum Contour : byte
{
    LeftUp = 1 << 0,
    Up = 1 << 1,
    RightUp = 1 << 2,
    Right = 1 << 3,
    RightDown = 1 << 4,
    Down = 1 << 5,
    LeftDown = 1 << 6,
    Left = 1 << 7,
}

public static class ContourMethods
{
    public static string ToKey(this Contour self)
        => $"{(byte)self}";

    public static Contour FromKey(string key)
        => byte.TryParse(key, out var flags) ? (Contour)flags : 0;
}
