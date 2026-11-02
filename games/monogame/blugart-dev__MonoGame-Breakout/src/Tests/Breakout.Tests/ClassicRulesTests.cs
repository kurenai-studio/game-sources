using System;
using Microsoft.Xna.Framework;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// The rule tables are the most test-worthy code in the repo: pure functions
/// encoding numbers transcribed from a 1976 manual, where a typo'd threshold
/// or a flipped sign would ship silently. Note what these tests never touch —
/// no game loop, no states, no graphics. The line between "unit-testable" and
/// "play-testable" in a game runs exactly along the pure/impure divide.
/// </summary>
public class ClassicRulesTests
{
    [Theory]
    [InlineData(0, false, 0, 0)]   // fresh serve: slowest speed
    [InlineData(3, false, 0, 0)]   // one brick shy of the first step
    [InlineData(4, false, 0, 1)]   // the manual's 4th-hit speed-up
    [InlineData(11, false, 1, 1)]
    [InlineData(12, false, 1, 2)]  // the 12th-hit speed-up
    [InlineData(0, true, 0, 3)]    // orange/red brick: instant top speed
    public void SpeedLevel_FollowsTheManualThresholds(
        int bricks, bool highRow, int current, int expected)
        => Assert.Equal(expected, ClassicRules.SpeedLevel(bricks, highRow, current));

    [Fact]
    public void SpeedLevel_NeverDecreases()
        => Assert.Equal(3, ClassicRules.SpeedLevel(0, false, 3));

    [Theory]
    [InlineData(0f)]
    [InlineData(0.49f)]
    [InlineData(-0.49f)]
    [InlineData(1f)]
    [InlineData(-1f)]
    public void PaddleRebound_IsAUnitVectorHeadingUp(float offset)
    {
        Vector2 direction = ClassicRules.PaddleRebound(offset, 0);
        Assert.Equal(1f, direction.Length(), 3);
        Assert.True(direction.Y < 0f, "rebound must head away from the paddle");
    }

    [Fact]
    public void PaddleRebound_IsNeverVertical()
    {
        // The 1976 law: no exactly perpendicular ball, even on a dead-center
        // hit (where naive math would emit X = 0 and a self-playing game).
        for (int level = 0; level < ClassicRules.Speeds.Length; level++)
            Assert.NotEqual(0f, ClassicRules.PaddleRebound(0f, level).X);
    }

    [Fact]
    public void PaddleRebound_SideFollowsTheStruckHalf()
    {
        Assert.True(ClassicRules.PaddleRebound(0.8f, 0).X > 0f);
        Assert.True(ClassicRules.PaddleRebound(-0.8f, 0).X < 0f);
    }

    [Fact]
    public void PaddleRebound_OuterQuarterIsWiderThanInner()
    {
        float inner = MathF.Abs(ClassicRules.PaddleRebound(0.2f, 0).X);
        float outer = MathF.Abs(ClassicRules.PaddleRebound(0.9f, 0).X);
        Assert.True(outer > inner);
    }

    [Fact]
    public void PaddleRebound_TightensTowardVerticalAsSpeedRises()
    {
        // "The angles of rebound become more perpendicular as the ball gets
        // faster" — |X| of the unit vector is sin(angle), so it must shrink.
        for (int level = 1; level < ClassicRules.Speeds.Length; level++)
        {
            Assert.True(MathF.Abs(ClassicRules.PaddleRebound(0.2f, level).X)
                < MathF.Abs(ClassicRules.PaddleRebound(0.2f, level - 1).X));
            Assert.True(MathF.Abs(ClassicRules.PaddleRebound(0.9f, level).X)
                < MathF.Abs(ClassicRules.PaddleRebound(0.9f, level - 1).X));
        }
    }

    [Fact]
    public void ServeDirection_IsAlwaysDownwardAndNeverVertical()
    {
        // Randomized rules get tested by sweeping seeds: 200 serves cover the
        // angle range far better than one hand-picked example would.
        for (int seed = 0; seed < 200; seed++)
        {
            Vector2 direction = ClassicRules.ServeDirection(new Random(seed));
            Assert.Equal(1f, direction.Length(), 3);
            Assert.True(direction.Y > 0f, "the 1976 machine serves AT the player");
            float sin12 = MathF.Sin(MathHelper.ToRadians(12f));
            float sin50 = MathF.Sin(MathHelper.ToRadians(50f));
            Assert.InRange(MathF.Abs(direction.X), sin12 - 0.001f, sin50 + 0.001f);
        }
    }

    [Fact]
    public void ServePosition_StaysMidScreenAwayFromTheEdges()
    {
        for (int seed = 0; seed < 200; seed++)
        {
            Vector2 position = ClassicRules.ServePosition(new Random(seed));
            Assert.InRange(position.X, 200f, Screen.Width - 200f);
            Assert.Equal(280f, position.Y);
        }
    }
}
