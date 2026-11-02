using Microsoft.Xna.Framework;
using Breakout.Entities;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// Collision response is the code most likely to harbor a sign error you'd
/// only meet once an hour in play. Geometry is trivially constructible in a
/// test — that's the advantage of entities being plain data.
/// </summary>
public class CollisionHelperTests
{
    [Fact]
    public void GetCollisionSide_NoOverlapMeansNone()
        => Assert.Equal(HitSide.None, CollisionHelper.GetCollisionSide(
            new Rectangle(0, 0, 10, 10), new Rectangle(50, 50, 10, 10)));

    [Theory]
    [InlineData(18, 30, HitSide.Left)]   // shallow overlap from the left
    [InlineData(42, 30, HitSide.Right)]  // shallow overlap from the right
    [InlineData(30, 18, HitSide.Top)]    // shallow overlap from above
    [InlineData(30, 42, HitSide.Bottom)] // shallow overlap from below
    public void GetCollisionSide_PicksTheShallowAxis(int x, int y, HitSide expected)
    {
        // 10x10 mover against a 20x20 target at (20,20): the mover sits
        // mostly outside one edge, so the overlap is thin on that axis.
        var mover = new Rectangle(x - 5, y - 5, 10, 10);
        var target = new Rectangle(20, 20, 20, 20);
        Assert.Equal(expected, CollisionHelper.GetCollisionSide(mover, target));
    }

    [Fact]
    public void ReflectAndSeparate_PointsVelocityAwayAndClearsTheOverlap()
    {
        var target = new Rectangle(100, 100, 60, 20);
        var ball = new Ball
        {
            Position = new Vector2(130, 98),   // overlapping the top edge
            Velocity = new Vector2(50, 120),   // heading down into the brick
        };

        CollisionHelper.ReflectAndSeparate(ball, target, HitSide.Top);

        Assert.True(ball.Velocity.Y < 0f, "velocity must point away from the brick");
        Assert.Equal(50f, ball.Velocity.X); // the other axis is untouched
        Assert.False(ball.Bounds.Intersects(target), "ball must be pushed clear");
    }

    [Fact]
    public void ReflectAndSeparate_IsIdempotentOnVelocity()
    {
        // The response sets the sign outright rather than negating, so a
        // double resolution cannot flip the ball back into the brick.
        var target = new Rectangle(100, 100, 60, 20);
        var ball = new Ball
        {
            Position = new Vector2(130, 98),
            Velocity = new Vector2(50, 120),
        };

        CollisionHelper.ReflectAndSeparate(ball, target, HitSide.Top);
        float onceY = ball.Velocity.Y;
        CollisionHelper.ReflectAndSeparate(ball, target, HitSide.Top);

        Assert.Equal(onceY, ball.Velocity.Y);
    }
}
