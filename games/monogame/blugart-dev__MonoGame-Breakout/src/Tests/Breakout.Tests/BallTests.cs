using System;
using Microsoft.Xna.Framework;
using Breakout.Entities;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// Entities are plain data plus motion, so their math tests directly — no
/// game loop required. These pin the aiming mechanic and the speed ramp,
/// the two knobs the whole game-feel hangs on.
/// </summary>
public class BallTests
{
    [Fact]
    public void BounceOffPaddle_CenterHitGoesStraightUp()
    {
        var paddle = new Paddle(); // single-player default: centered at 400
        var ball = new Ball
        {
            Position = new Vector2(paddle.Bounds.Center.X, paddle.Bounds.Top),
            Velocity = new Vector2(100, 200),
        };

        ball.BounceOffPaddle(paddle);

        Assert.Equal(0f, ball.Velocity.X, 3);
        Assert.True(ball.Velocity.Y < 0f);
        Assert.True(ball.Bounds.Bottom <= paddle.Bounds.Top, "lifted clear of the paddle");
    }

    [Fact]
    public void BounceOffPaddle_EdgeHitLeavesAtTheMaxAngle()
    {
        var paddle = new Paddle();
        var ball = new Ball
        {
            Position = new Vector2(paddle.Bounds.Right, paddle.Bounds.Top),
            Velocity = new Vector2(0, 200),
        };

        ball.BounceOffPaddle(paddle);

        // Max bounce angle is 60° from vertical: X = sin(60°) x speed.
        float expectedX = MathF.Sin(MathHelper.Pi / 3f) * ball.Speed;
        Assert.Equal(expectedX, ball.Velocity.X, 1);
    }

    [Fact]
    public void BounceOffPaddle_PreservesSpeed()
    {
        var paddle = new Paddle();
        var ball = new Ball
        {
            Position = new Vector2(paddle.Bounds.Center.X + 30, paddle.Bounds.Top),
            Velocity = new Vector2(123, 234),
        };

        ball.BounceOffPaddle(paddle);

        Assert.Equal(ball.Speed, ball.Velocity.Length(), 2);
    }

    [Fact]
    public void RampSpeed_ClimbsThenCapsAtMax()
    {
        var ball = new Ball { Velocity = new Vector2(0, 100) };
        float initial = ball.Speed;

        ball.RampSpeed();
        Assert.True(ball.Speed > initial);

        for (int i = 0; i < 200; i++)
            ball.RampSpeed();
        float capped = ball.Speed;
        ball.RampSpeed();
        Assert.Equal(capped, ball.Speed); // the ceiling holds

        // Velocity is rescaled to match the ramped speed, not left stale.
        Assert.Equal(ball.Speed, ball.Velocity.Length(), 2);
    }

    [Fact]
    public void Split_PreservesPositionAndSpeed()
    {
        var ball = new Ball
        {
            Position = new Vector2(300, 200),
            Velocity = new Vector2(0, -320),
        };

        Ball clone = ball.Split(MathHelper.ToRadians(25f));

        Assert.Equal(ball.Position, clone.Position);
        Assert.Equal(ball.Velocity.Length(), clone.Velocity.Length(), 2);
        Assert.NotEqual(ball.Velocity, clone.Velocity); // rotated, so it fans out
    }

    [Fact]
    public void Launch_HeadsUpwardWithinTheLaunchCone()
    {
        for (int seed = 0; seed < 100; seed++)
        {
            var ball = new Ball();
            ball.Launch(new Random(seed));

            Assert.True(ball.Velocity.Y < 0f);
            Assert.Equal(ball.Speed, ball.Velocity.Length(), 2);

            // The launch cone is ±~26° from vertical (Pi/7).
            float maxX = MathF.Sin(MathHelper.Pi / 7f) * ball.Speed;
            Assert.InRange(MathF.Abs(ball.Velocity.X), 0f, maxX + 0.01f);
        }
    }
}
