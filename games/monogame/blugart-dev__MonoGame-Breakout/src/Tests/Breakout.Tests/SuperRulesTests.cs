using System;
using Microsoft.Xna.Framework;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>The 1978 numbers, tested the same way as the 1976 ones.</summary>
public class SuperRulesTests
{
    [Theory]
    [InlineData(0, false, 0, 0)]
    [InlineData(4, false, 0, 1)]   // 4th paddle return
    [InlineData(8, false, 1, 2)]   // 8th
    [InlineData(12, false, 2, 3)]  // 12th
    [InlineData(0, true, 0, 4)]    // 5/7-point brick: instant top speed
    public void SpeedLevel_FollowsTheManualThresholds(
        int returns, bool highBrick, int current, int expected)
        => Assert.Equal(expected, SuperRules.SpeedLevel(returns, highBrick, current));

    [Fact]
    public void SpeedLevel_NeverDecreases()
        => Assert.Equal(4, SuperRules.SpeedLevel(0, false, 4));

    [Fact]
    public void PaddleRebound_IsNeverVerticalOnAnyRung()
    {
        for (int level = 0; level < SuperRules.Speeds.Length; level++)
        {
            Vector2 direction = SuperRules.PaddleRebound(0f, level);
            Assert.Equal(1f, direction.Length(), 3);
            Assert.NotEqual(0f, direction.X);
            Assert.True(direction.Y < 0f);
        }
    }

    [Fact]
    public void CaptiveDirection_IsAUnitVector()
    {
        for (int seed = 0; seed < 100; seed++)
            Assert.Equal(1f, SuperRules.CaptiveDirection(new Random(seed)).Length(), 3);
    }
}
