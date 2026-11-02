using System.Collections.Generic;
using Breakout.Entities;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// The 1976 wall, checked against the manual the same way the rule tables
/// are: 8 rows of 14 one-hit bricks, row pairs scored 1/3/5/7 from the
/// paddle outward, 448 points per wall — times the game's two walls, the
/// famous 896 maximum. These numbers are transcriptions, so a typo would
/// ship silently; here it fails by name instead.
/// </summary>
public class ClassicWallTests
{
    [Fact]
    public void Build_Is8x14OneHitBricks()
    {
        List<Brick> wall = ClassicWall.Build();

        Assert.Equal(ClassicWall.Rows * ClassicWall.Columns, wall.Count); // 112
        Assert.All(wall, b => Assert.Equal(1, b.HitPoints));
        Assert.All(wall, b => Assert.False(b.IsUnbreakable));
    }

    [Fact]
    public void Build_WallIsWorthExactly448()
    {
        int total = 0;
        foreach (Brick brick in ClassicWall.Build())
            total += brick.ScoreValue;

        Assert.Equal(448, total); // x2 walls = the 896-point maximum
    }

    [Fact]
    public void Build_RowPairsScore7753311FromTheBackwallDown()
    {
        // Build emits row-major from the backwall down, so index / Columns
        // is the row. 7/7/5/5/3/3/1/1 — i.e. 1/1/3/3/5/5/7/7 from the paddle
        // outward, as the manual prices them.
        List<Brick> wall = ClassicWall.Build();
        int[] expected = { 7, 7, 5, 5, 3, 3, 1, 1 };

        for (int i = 0; i < wall.Count; i++)
            Assert.Equal(expected[i / ClassicWall.Columns], wall[i].ScoreValue);
    }

    [Fact]
    public void Build_TheWholeWallSitsBelowTheBreakoutLine()
    {
        // The breakout zone is BETWEEN the rearmost row and the backwall. A
        // brick above the line would fire the half-paddle penalty on an
        // ordinary back-row hit instead of an actual breakthrough.
        Assert.All(ClassicWall.Build(),
            b => Assert.True(b.Bounds.Top >= ClassicWall.BreakoutLineY));
    }
}
