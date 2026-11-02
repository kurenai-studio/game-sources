using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Breakout.Entities;

namespace Breakout.Systems;

/// <summary>
/// The 1976 wall, straight from the original operation manual: 8 rows of 14
/// one-hit bricks. Row pairs score 1/3/5/7 points from the paddle outward, so
/// a full wall is worth exactly 448 points — and since the game serves exactly
/// two walls, the famous maximum score is 896. The original machine had a
/// black-and-white monitor; the row colors were cellophane strips glued to the
/// glass, which is why color comes in two-row bands (yellow, green, orange,
/// red from the bottom up) rather than per brick.
/// </summary>
public static class ClassicWall
{
    public const int Rows = 8;
    public const int Columns = 14;

    private const int CellWidth = Screen.Width / Columns;
    private const int CellHeight = 18;
    private const int TopY = 70; // below the HUD strip

    /// <summary>
    /// The manual calls the zone between the rearmost brick row and the
    /// backwall a "breakout" — a ball whose center crosses above this line
    /// triggers the half-width paddle penalty for the rest of the volley.
    /// </summary>
    public const float BreakoutLineY = TopY;

    // Integer division loses a few pixels; center the wall to hide it.
    private static readonly int OffsetX = (Screen.Width - Columns * CellWidth) / 2;

    // Index 0 = rearmost row (nearest the backwall). Cellophane band colors.
    private static readonly int[] RowScores = { 7, 7, 5, 5, 3, 3, 1, 1 };
    private static readonly Color[] RowColors =
    {
        new(255, 77, 77),   // red      7 pts
        new(255, 77, 77),
        new(255, 138, 48),  // orange   5 pts
        new(255, 138, 48),
        new(87, 212, 118),  // green    3 pts
        new(87, 212, 118),
        new(255, 205, 66),  // yellow   1 pt
        new(255, 205, 66),
    };

    public static List<Brick> Build()
    {
        var bricks = new List<Brick>(Rows * Columns);
        for (int row = 0; row < Rows; row++)
            for (int col = 0; col < Columns; col++)
            {
                var bounds = new Rectangle(
                    OffsetX + col * CellWidth + 1,
                    TopY + row * CellHeight + 1,
                    CellWidth - 2,
                    CellHeight - 2);
                bricks.Add(new Brick(bounds,
                    hitPoints: 1, scoreValue: RowScores[row], RowColors[row]));
            }
        return bricks;
    }
}
