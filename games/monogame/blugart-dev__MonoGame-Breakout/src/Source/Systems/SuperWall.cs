using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Breakout.Entities;

namespace Breakout.Systems;

/// <summary>
/// The three 1978 playfields, straight from the Super Breakout operation
/// manual. Every variant is 13 columns wide (the manual says "4 x 13" five
/// separate times). Double and Cavity stack two four-row walls — orange over
/// green, scored 7/7/5/5/3/3/1/1 from the top down; Cavity additionally cuts
/// two 2x2 holes into the orange wall and seals a captive ball in each.
/// Progressive prices bricks by *position* instead: the screen has four fixed
/// color zones (blue 7, orange 5, green 3, yellow 1), so a row is worth less
/// every time it scrolls down — and rows enter forever, four of bricks then
/// four of blanks.
/// </summary>
public static class SuperWall
{
    public const int Columns = 13;
    public const int CellHeight = 18;

    private const int TopY = 70; // below the HUD strip, like the classic wall
    private const int WallRows = 8; // Double/Cavity: 4 orange over 4 green

    /// <summary>The vertical band the Double/Cavity wall occupies — the zone
    /// a ball must be clear of before a rebuilt wall may materialize.</summary>
    public const int WallTop = TopY;
    public const int WallBottom = TopY + WallRows * CellHeight;

    /// <summary>
    /// Where Progressive rows retire (manual Figure 2-9: "the row of bricks
    /// closest to the paddle disappears"). Just *above* the paddle, with room
    /// for the ball: culling exactly at the paddle line left a 1 px slot the
    /// 10 px ball could never fit through, so every paddle return met a brick
    /// face instantly and the ball rallied between paddle and wall with the
    /// player as a spectator.
    /// </summary>
    public const int RetirementY = Paddle.DefaultY - Ball.Size - 2;

    private const int CellWidth = Screen.Width / Columns;
    private static readonly int OffsetX = (Screen.Width - Columns * CellWidth) / 2;

    private static readonly Color Blue = new(94, 167, 255);
    private static readonly Color Orange = new(255, 138, 48);
    private static readonly Color Green = new(87, 212, 118);
    private static readonly Color Yellow = new(255, 205, 66);

    // Double/Cavity row values, top row first. The manual: "the upper two
    // rows of orange bricks are worth 7 points ... 5 points for the lower two
    // orange rows, 3 points for the upper two rows of green bricks and 1
    // point for the lower two rows of green bricks".
    private static readonly int[] WallScores = { 7, 7, 5, 5, 3, 3, 1, 1 };

    /// <summary>
    /// Cavity's two 2x2 holes, in pixels. The manual: "at approximately 3
    /// columns in and 2 rows down into the orange brick wall, from both the
    /// left and the right". Columns 3-4 and 8-9 (mirrored), rows 1-2 — one
    /// orange row above and below each hole, 44 orange bricks remaining.
    /// </summary>
    public static readonly Rectangle[] CavityHoles =
    {
        CellArea(col: 3, row: 1, cols: 2, rows: 2),
        CellArea(col: 8, row: 1, cols: 2, rows: 2),
    };

    public static List<Brick> BuildDouble() => BuildWall(withCavities: false);

    public static List<Brick> BuildCavity() => BuildWall(withCavities: true);

    private static List<Brick> BuildWall(bool withCavities)
    {
        var bricks = new List<Brick>(WallRows * Columns);
        for (int row = 0; row < WallRows; row++)
            for (int col = 0; col < Columns; col++)
            {
                Rectangle bounds = BrickBounds(col, row);
                if (withCavities && IsInsideCavity(bounds))
                    continue;
                bricks.Add(new Brick(bounds,
                    hitPoints: 1, WallScores[row], row < 4 ? Orange : Green));
            }
        return bricks;
    }

    private static bool IsInsideCavity(Rectangle brickBounds)
    {
        foreach (Rectangle hole in CavityHoles)
            if (hole.Contains(brickBounds.Center))
                return true;
        return false;
    }

    // ----- Progressive -----

    /// <summary>
    /// The opening Progressive board: a blue wall at the top, a wall-sized
    /// gap, a green wall at mid-screen ("then occurs a space equivalent to
    /// this wall") — the first two bands of the endless pattern, already
    /// sitting in their matching color zones.
    /// </summary>
    public static List<Brick> BuildProgressiveBoard()
    {
        var bricks = new List<Brick>(2 * 4 * Columns);
        for (int row = 0; row < 12; row++)
        {
            if (row is >= 4 and < 8)
                continue; // the gap between the two walls
            for (int col = 0; col < Columns; col++)
                bricks.Add(MakeProgressiveBrick(col, row));
        }
        return bricks;
    }

    /// <summary>
    /// One step of the conveyor. Every brick drops a row and is re-stamped
    /// with its new zone's value and color ("as the brick walls scroll down,
    /// their colors change, which indicates a new point score for that brick
    /// at that instant of time"); bricks leaving the screen are lost, "not
    /// counted toward or against the player's score"; and the endless pattern
    /// feeds the top — four rows of blanks, then four rows of bricks. The
    /// phase counter lives on the session, not here and not in a state: the
    /// pattern must continue seamlessly across serves, and a playing state
    /// dies with its serve.
    /// </summary>
    public static void ScrollProgressive(List<Brick> bricks, ref int rowPhase,
        IReadOnlyList<Ball> balls = null)
    {
        foreach (Brick brick in bricks)
        {
            brick.ShiftDown(CellHeight);
            brick.Reclassify(ZoneScore(brick.Bounds.Center.Y), ZoneColor(brick.Bounds.Center.Y));
        }

        // Rows retire at the line above the paddle, uncounted either way. A
        // brick that lands ON a ball retires the same way: the scroll is an
        // 18 px teleport, and discrete collision can only push the ball out
        // of a brick that materialized around it — often through the bottom
        // face, flinging a just-returned ball straight back at the gutter.
        // Same law as the Double/Cavity wall rebuild: nothing may
        // materialize on top of a ball.
        bricks.RemoveAll(b => b.Bounds.Bottom >= RetirementY || LandsOnBall(b, balls));

        // Phase 0 begins with blanks: the opening board's blue wall has just
        // "entered", so the pattern continues with the gap above it.
        bool brickRow = rowPhase % 8 >= 4;
        rowPhase++;
        if (brickRow)
            for (int col = 0; col < Columns; col++)
            {
                // Spawn one row above the screen and ShiftDown into place, so
                // a fed row rides the same slide animation as the rest of the
                // wall instead of popping in. (Row -1's center still maps to
                // zone 0 — integer division truncates toward zero — so the
                // brick is priced as if it were already in place.)
                Brick brick = MakeProgressiveBrick(col, row: -1);
                brick.ShiftDown(CellHeight);
                bricks.Add(brick);
            }
    }

    private static bool LandsOnBall(Brick brick, IReadOnlyList<Ball> balls)
    {
        if (balls == null)
            return false;

        foreach (Ball ball in balls)
        {
            Rectangle space = ball.Bounds;
            space.Inflate(2, 2); // breathing room, not merely non-overlap
            if (brick.Bounds.Intersects(space))
                return true;
        }
        return false;
    }

    private static Brick MakeProgressiveBrick(int col, int row)
    {
        Rectangle bounds = BrickBounds(col, row);
        return new Brick(bounds,
            hitPoints: 1, ZoneScore(bounds.Center.Y), ZoneColor(bounds.Center.Y));
    }

    // Four fixed zones of four rows each, top to bottom; everything below
    // the yellow zone stays yellow until it scrolls off.
    private static int Zone(int centerY) => Math.Min(3, (centerY - TopY) / (CellHeight * 4));

    private static int ZoneScore(int centerY)
        => Zone(centerY) switch { 0 => 7, 1 => 5, 2 => 3, _ => 1 };

    private static Color ZoneColor(int centerY)
        => Zone(centerY) switch { 0 => Blue, 1 => Orange, 2 => Green, _ => Yellow };

    // Integer division loses a few pixels; center the wall to hide it.
    private static Rectangle BrickBounds(int col, int row) => new(
        OffsetX + col * CellWidth + 1, TopY + row * CellHeight + 1,
        CellWidth - 2, CellHeight - 2);

    private static Rectangle CellArea(int col, int row, int cols, int rows) => new(
        OffsetX + col * CellWidth, TopY + row * CellHeight,
        cols * CellWidth, rows * CellHeight);
}
