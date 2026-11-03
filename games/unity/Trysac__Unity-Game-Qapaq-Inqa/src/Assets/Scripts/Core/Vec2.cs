using System;

namespace QapaqInqa.Core
{
    /// <summary>A small engine-free 2D vector, so the rules compile without UnityEngine.</summary>
    public readonly struct Vec2 : IEquatable<Vec2>
    {
        public static readonly Vec2 Zero = new Vec2(0f, 0f);

        public Vec2(float x, float y)
        {
            X = x;
            Y = y;
        }

        public float X { get; }
        public float Y { get; }

        public float Length => (float)Math.Sqrt(X * X + Y * Y);

        public static Vec2 operator +(Vec2 a, Vec2 b) => new Vec2(a.X + b.X, a.Y + b.Y);
        public static Vec2 operator -(Vec2 a, Vec2 b) => new Vec2(a.X - b.X, a.Y - b.Y);
        public static Vec2 operator *(Vec2 a, float k) => new Vec2(a.X * k, a.Y * k);

        public bool Equals(Vec2 other) => X.Equals(other.X) && Y.Equals(other.Y);
        public override bool Equals(object obj) => obj is Vec2 other && Equals(other);
        public override int GetHashCode() => (X.GetHashCode() * 397) ^ Y.GetHashCode();
        public override string ToString() => $"({X:0.###}, {Y:0.###})";
    }

    /// <summary>An axis-aligned box given by its bottom-centre (feet) and size, as every body in the game is.</summary>
    public readonly struct Box
    {
        public Box(float centerX, float bottom, float width, float height)
        {
            Left = centerX - width / 2f;
            Right = centerX + width / 2f;
            Bottom = bottom;
            Top = bottom + height;
        }

        public float Left { get; }
        public float Right { get; }
        public float Bottom { get; }
        public float Top { get; }
        public float CenterX => (Left + Right) / 2f;
        public float CenterY => (Bottom + Top) / 2f;

        public bool Overlaps(Box other) =>
            Left < other.Right && other.Left < Right && Bottom < other.Top && other.Bottom < Top;
    }
}
