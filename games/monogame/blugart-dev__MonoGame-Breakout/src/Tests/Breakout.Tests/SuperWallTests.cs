using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Breakout.Entities;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// The 1978 playfields, checked against TM-118 like the rule tables. Double
/// and Cavity stack two 4x13 walls scored 7/7/5/5/3/3/1/1 from the top down;
/// Cavity cuts two 2x2 holes into the orange wall (44 orange bricks remain);
/// Progressive prices a brick by the screen zone it currently occupies and
/// feeds rows in an endless four-of-bricks/four-of-blanks pattern.
/// </summary>
public class SuperWallTests
{
    [Fact]
    public void BuildDouble_IsTwoStacked4x13WallsWorth416()
    {
        List<Brick> wall = SuperWall.BuildDouble();
        Assert.Equal(8 * SuperWall.Columns, wall.Count); // 104

        int total = 0;
        foreach (Brick brick in wall)
            total += brick.ScoreValue;
        Assert.Equal(416, total); // (7+7+5+5+3+3+1+1) x 13
    }

    [Fact]
    public void BuildCavity_CutsTwo2x2HolesAndNothingStandsInside()
    {
        List<Brick> wall = SuperWall.BuildCavity();
        Assert.Equal(8 * SuperWall.Columns - 8, wall.Count); // 96

        foreach (Brick brick in wall)
            foreach (Rectangle hole in SuperWall.CavityHoles)
                Assert.False(hole.Contains(brick.Bounds.Center),
                    "no brick may stand inside a cavity");
    }

    [Fact]
    public void BuildCavity_Leaves44OrangeBricks()
    {
        // The manual's arithmetic: 4x13 orange bricks minus two 2x2 holes.
        // Orange is the upper wall — the 7- and 5-point rows.
        int orange = 0;
        foreach (Brick brick in SuperWall.BuildCavity())
            if (brick.ScoreValue >= 5)
                orange++;

        Assert.Equal(44, orange);
    }

    [Fact]
    public void BuildProgressiveBoard_OpensWithBlueAndGreenWallsInTheirZones()
    {
        // The opening board: a blue wall at the top (zone value 7), a
        // wall-sized gap, a green wall at mid-screen (zone value 3).
        List<Brick> board = SuperWall.BuildProgressiveBoard();
        Assert.Equal(8 * SuperWall.Columns, board.Count);

        Assert.All(board, b => Assert.True(b.ScoreValue is 7 or 3,
            "opening walls sit in the blue (7) and green (3) zones"));
    }

    [Fact]
    public void ScrollProgressive_RepricesEveryBrickByItsNewZone()
    {
        List<Brick> board = SuperWall.BuildProgressiveBoard();
        int phase = 0;

        // Four steps move the blue wall fully into the orange zone (and the
        // green wall into the yellow one). "A new point score for that brick
        // at that instant of time" — nothing may keep its old price.
        for (int i = 0; i < 4; i++)
            SuperWall.ScrollProgressive(board, ref phase);

        Assert.DoesNotContain(board, b => b.ScoreValue == 7);
        Assert.Contains(board, b => b.ScoreValue == 5); // the ex-blue wall
        Assert.Contains(board, b => b.ScoreValue == 1); // the ex-green wall
    }

    [Fact]
    public void ScrollProgressive_FeedsRowsFourOnFourOff()
    {
        // Start from an empty field to watch the feed pattern alone. Phase 0
        // begins with the gap above the opening board's just-entered blue
        // wall: four blank steps, then four rows of bricks, forever.
        var board = new List<Brick>();
        int phase = 0;

        var added = new List<int>();
        for (int i = 0; i < 16; i++)
        {
            int before = board.Count;
            SuperWall.ScrollProgressive(board, ref phase);
            added.Add(board.Count - before);
        }

        int c = SuperWall.Columns;
        Assert.Equal(new[] { 0, 0, 0, 0, c, c, c, c, 0, 0, 0, 0, c, c, c, c }, added);
    }

    [Fact]
    public void ScrollProgressive_RetiresRowsAboveThePaddleWithBallClearance()
    {
        // The retirement line must leave at least a ball's worth of daylight
        // above the paddle — culling at the paddle line itself left a slot
        // the ball could not fit through, so every return met a brick.
        Assert.True(Paddle.DefaultY - SuperWall.RetirementY >= Ball.Size,
            "the gap between the lowest brick and the paddle must fit the ball");

        List<Brick> board = SuperWall.BuildProgressiveBoard();
        int phase = 0;

        // Long enough for the opening walls to reach the bottom and leave.
        for (int i = 0; i < 40; i++)
        {
            SuperWall.ScrollProgressive(board, ref phase);
            Assert.All(board, b => Assert.True(b.Bounds.Bottom < SuperWall.RetirementY,
                "bricks must never cross the retirement line"));
        }
    }

    [Fact]
    public void ScrollProgressive_NeverLandsABrickOnABall()
    {
        // The scroll is an 18 px teleport; a brick that would materialize on
        // a ball retires uncounted instead, like a row reaching the bottom.
        List<Brick> board = SuperWall.BuildProgressiveBoard();
        int phase = 0;

        // Parked just under the opening green wall (bottom edge y = 286),
        // directly in the conveyor's path.
        var ball = new Ball { Position = new Vector2(400f, 300f) };
        var balls = new List<Ball> { ball };

        for (int i = 0; i < 12; i++)
        {
            SuperWall.ScrollProgressive(board, ref phase, balls);
            Assert.All(board, b => Assert.False(b.Bounds.Intersects(ball.Bounds),
                "no scroll step may leave a brick overlapping a ball"));
        }
    }
}
