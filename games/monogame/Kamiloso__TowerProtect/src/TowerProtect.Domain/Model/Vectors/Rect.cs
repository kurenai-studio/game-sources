using System;

namespace TowerProtect.Domain.Model.Vectors;

public readonly record struct Rect(Vec2 Center, Vec2 Size)
{
    public Vec2 CornerMain => Center - Size / 2.0;
    public Vec2 CornerOpposite => Center + Size / 2.0;

    public Vec2 MinCorner => Vec2.MinCorner(CornerMain, CornerOpposite);
    public Vec2 MaxCorner => Vec2.MaxCorner(CornerMain, CornerOpposite);

    public Rect(Vec2 center, double side) : this(center, new Vec2(side, side)) { } // square
    public Rect(Vec2 center) : this(center, 1.0) { } // unit square

    public bool Contains(Vec2 point)
    {
        return point.x >= MinCorner.x && point.x <= MaxCorner.x &&
            point.y >= MinCorner.y && point.y <= MaxCorner.y;
    }

    public void GridIterate(Action<Vec2Int> action)
    {
        Vec2Int min = MinCorner.Floor();
        Vec2Int max = MaxCorner.Ceiling();

        for (int x = min.x; x <= max.x; x ++)
            for (int y = min.y; y <= max.y; y ++)
            {
                action(new Vec2Int(x, y));
            }
    }

    public static Vec2 MapPoint(Vec2 point, Rect sourceRect, Rect targetRect)
    {
        Vec2 sourceDelta = point - sourceRect.CornerMain;
        Vec2 targetDelta = new(
            x: sourceDelta.x * targetRect.Size.x / sourceRect.Size.x,
            y: sourceDelta.y * targetRect.Size.y / sourceRect.Size.y
        );

        return targetRect.CornerMain + targetDelta;
    }

    public static Vec2 MapVector(Vec2 vector, Rect sourceRect, Rect targetRect)
    {
        return new Vec2(
            x: vector.x * targetRect.Size.x / sourceRect.Size.x,
            y: vector.y * targetRect.Size.y / sourceRect.Size.y
        );
    }

    public static Rect MapRect(Rect rect, Rect sourceRect, Rect targetRect)
    {
        Vec2 targetCenter = MapPoint(rect.Center, sourceRect, targetRect);
        Vec2 targetSize = MapVector(rect.Size, sourceRect, targetRect);

        return new Rect(targetCenter, targetSize);
    }
}
