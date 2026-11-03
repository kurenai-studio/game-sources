#pragma warning disable IDE1006 // Naming Styles

using System;
using System.Collections.Immutable;
using System.Globalization;
using System.Text.Json.Serialization;

namespace TowerProtect.Domain.Model.Vectors;

public readonly record struct Vec2(double x, double y)
{
    [JsonIgnore] public double Magnitude => Math.Sqrt(x * x + y * y);
    [JsonIgnore] public double SqrMagnitude => x * x + y * y;
    [JsonIgnore] public Vec2 Normalized => Magnitude > 1E-15 ? this / Magnitude : Right;
    [JsonIgnore] public Vec2 Abs => new(Math.Abs(x), Math.Abs(y));

    public Vec2 Rotate(double angle)
    {
        return new Vec2(
            x: x * Math.Cos(angle) - y * Math.Sin(angle),
            y: x * Math.Sin(angle) + y * Math.Cos(angle)
        );
    }

    public Vec2Int Round() => RoundInternal(Math.Round);
    public Vec2Int Floor() => RoundInternal(Math.Floor);
    public Vec2Int Ceiling() => RoundInternal(Math.Ceiling);

    private Vec2Int RoundInternal(Func<double, double> round)
    {
        return new Vec2Int(
            x: double.IsNaN(x) ? 0 : (int)Math.Clamp(round(x), int.MinValue, int.MaxValue),
            y: double.IsNaN(y) ? 0 : (int)Math.Clamp(round(y), int.MinValue, int.MaxValue)
        );
    }

    public static double Distance(Vec2 a, Vec2 b)
    {
        double dx = a.x - b.x;
        double dy = a.y - b.y;

        return Math.Sqrt(dx * dx + dy * dy);
    }

    public static double Dot(Vec2 a, Vec2 b) => a.x * b.x + a.y * b.y;
    public static double Cross(Vec2 a, Vec2 b) => a.x * b.y - a.y * b.x;

    public override string ToString()
    {
        string xs = x.ToString(CultureInfo.InvariantCulture);
        string ys = y.ToString(CultureInfo.InvariantCulture);

        return $"({xs}, {ys})";
    }

    public static readonly Vec2 Zero = new(0, 0);
    public static readonly Vec2 One = new(1, 1);
    public static readonly Vec2 Up = new(0, -1);
    public static readonly Vec2 Down = new(0, 1);
    public static readonly Vec2 Left = new(-1, 0);
    public static readonly Vec2 Right = new(1, 0);

    public static ImmutableArray<Vec2> MainDirections => [ Up, Right, Down, Left ];

    public static Vec2 MinCorner(Vec2 a, Vec2 b) => new(Math.Min(a.x, b.x), Math.Min(a.y, b.y));
    public static Vec2 MaxCorner(Vec2 a, Vec2 b) => new(Math.Max(a.x, b.x), Math.Max(a.y, b.y));

    public static Vec2 operator +(Vec2 a, Vec2 b) => new(a.x + b.x, a.y + b.y);
    public static Vec2 operator -(Vec2 a, Vec2 b) => new(a.x - b.x, a.y - b.y);
    public static Vec2 operator -(Vec2 a) => new(-a.x, -a.y);
    public static Vec2 operator +(Vec2 a) => a;

    public static Vec2 operator *(Vec2 a, double d) => new(a.x * d, a.y * d);
    public static Vec2 operator *(double d, Vec2 a) => new(a.x * d, a.y * d);
    public static Vec2 operator /(Vec2 a, double d) => new(a.x / d, a.y / d);
}
