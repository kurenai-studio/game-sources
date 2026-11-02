using System;
using Microsoft.Xna.Framework;
using Breakout.Entities;

namespace Breakout.Systems;

/// <summary>Which side of the target rectangle was struck.</summary>
public enum HitSide { None, Left, Right, Top, Bottom }

/// <summary>
/// Minimal-penetration AABB resolution: of the two axes of the overlap
/// rectangle, the shallower one is the axis of impact, and the relative centers
/// disambiguate which side. This is the classic discrete technique; it is exact
/// enough here because the ball moves at most ~9 px per 60 Hz tick against
/// 20 px bricks, so it can never tunnel through a target in one step. A faster
/// ball or thinner targets would call for a swept (continuous) test instead.
/// </summary>
public static class CollisionHelper
{
    public static HitSide GetCollisionSide(Rectangle moving, Rectangle target)
    {
        Rectangle overlap = Rectangle.Intersect(moving, target);
        if (overlap.IsEmpty)
            return HitSide.None;

        if (overlap.Width < overlap.Height)
            return moving.Center.X < target.Center.X ? HitSide.Left : HitSide.Right;

        return moving.Center.Y < target.Center.Y ? HitSide.Top : HitSide.Bottom;
    }

    /// <summary>
    /// Push the ball out of the rectangle along the impact axis, then point
    /// the velocity away from it. Setting the sign outright (rather than
    /// negating) makes the response idempotent if we ever resolve twice.
    /// Shared by both rule sets — how a ball leaves a brick is physics, not
    /// rules, so it lives here rather than in either playing state.
    /// </summary>
    public static void ReflectAndSeparate(Ball ball, Rectangle target, HitSide side)
    {
        Rectangle overlap = Rectangle.Intersect(ball.Bounds, target);
        switch (side)
        {
            case HitSide.Left:
                ball.Position.X -= overlap.Width;
                ball.Velocity.X = -MathF.Abs(ball.Velocity.X);
                break;
            case HitSide.Right:
                ball.Position.X += overlap.Width;
                ball.Velocity.X = MathF.Abs(ball.Velocity.X);
                break;
            case HitSide.Top:
                ball.Position.Y -= overlap.Height;
                ball.Velocity.Y = -MathF.Abs(ball.Velocity.Y);
                break;
            case HitSide.Bottom:
                ball.Position.Y += overlap.Height;
                ball.Velocity.Y = MathF.Abs(ball.Velocity.Y);
                break;
        }
    }
}
