#pragma warning disable IDE1006 // Naming Styles

using System;
using System.Collections.Immutable;
using System.Text.Json.Serialization;

namespace TowerProtect.Domain.Model.Vectors;

public readonly record struct Vec2Int(int x, int y)
{
    [JsonIgnore] public int MinAbs => Math.Min(Math.Abs(x), Math.Abs(y));
    [JsonIgnore] public int MaxAbs => Math.Max(Math.Abs(x), Math.Abs(y));
    [JsonIgnore] public Vec2Int Orthogonal => Rot90(1);

    public Vec2Int Rot90(int rots)
    {
        Vec2Int self = this;

        rots %= 4;
        while (rots % 4 != 0)
        {
            self = new Vec2Int(-self.y, self.x);
            rots--;
        }

        return self;
    }

    public bool Contains(Vec2 other) => other.Round() == this;

    public override string ToString() => $"({x}, {y})";

    public static readonly Vec2Int Zero = new(0, 0);
    public static readonly Vec2Int One = new(1, 1);
    public static readonly Vec2Int Up = new(0, -1);
    public static readonly Vec2Int Down = new(0, 1);
    public static readonly Vec2Int Left = new(-1, 0);
    public static readonly Vec2Int Right = new(1, 0);

    public static ImmutableArray<Vec2Int> MainDirections { get; } = [Up, Right, Down, Left];

    public static Vec2Int MinCorner(Vec2Int a, Vec2Int b) => new(Math.Min(a.x, b.x), Math.Min(a.y, b.y));
    public static Vec2Int MaxCorner(Vec2Int a, Vec2Int b) => new(Math.Max(a.x, b.x), Math.Max(a.y, b.y));

    public static Vec2Int operator +(Vec2Int a) => a;
    public static Vec2Int operator -(Vec2Int a) => new(-a.x, -a.y);

    public static Vec2Int operator +(Vec2Int a, Vec2Int b) => new(a.x + b.x, a.y + b.y);
    public static Vec2Int operator -(Vec2Int a, Vec2Int b) => new(a.x - b.x, a.y - b.y);

    public static Vec2Int operator *(Vec2Int a, int d) => new(a.x * d, a.y * d);
    public static Vec2Int operator *(int d, Vec2Int a) => new(d * a.x, d * a.y);
    public static Vec2Int operator /(Vec2Int a, int d) => new(a.x / d, a.y / d);

    public static Vec2Int operator >>(Vec2Int a, int d) => new(a.x >> d, a.y >> d);
    public static Vec2Int operator <<(Vec2Int a, int d) => new(a.x << d, a.y << d);

    public Vec2 ToVec2() => new(x, y);
    public static implicit operator Vec2(Vec2Int source) => source.ToVec2();
}
