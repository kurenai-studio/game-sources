using System;
using System.Text;

namespace Breakout.Systems;

/// <summary>
/// Emits boards in the exact plain-text format LevelLoader parses. This is
/// where "levels are data" pays off a second time: because the game reads a
/// format instead of hard-coding walls, a generator is just another producer
/// of that format — LevelLoader cannot tell (and never learns) whether its
/// text came from a file or from here. The output is even legal to paste
/// into a .txt level if a generated board turns out to be a keeper.
/// </summary>
public static class BoardGenerator
{
    private const int Columns = 13; // must match LevelLoader's grid

    // Mirrored boards generate only the left half plus the center column;
    // the right half is a reflection. Symmetry is doing two jobs: it makes
    // random output read as *designed* (humans forgive randomness far more
    // readily when it has structure), and it halves the space the generator
    // can get wrong.
    private const int HalfColumns = Columns / 2 + 1;

    /// <summary>
    /// Build board text for the given 0-based board number. All randomness
    /// comes from the caller's Random — in play that is the session's seeded
    /// stream, which is what keeps generated runs replayable: the replay
    /// re-rolls the same boards because it re-seeds the same generator.
    /// </summary>
    public static string Generate(Random rng, int boardNumber)
    {
        // The difficulty knobs, each a small function of progress. Tuning a
        // generator IS tuning these curves — caps keep late boards hard but
        // never degenerate (a screen of 5s and Xs is a wall, not a level).
        int rows = Math.Min(5 + boardNumber / 2, 8);
        int tierCap = Math.Min(2 + boardNumber / 2, 5);
        int tierBudget = 35 + boardNumber * 10;
        float unbreakableDensity = Math.Min(0.012f * boardNumber, 0.10f);

        var grid = new char[rows, Columns];
        for (int row = 0; row < rows; row++)
            for (int col = 0; col < Columns; col++)
                grid[row, col] = '.';

        // Spend the tier budget brick by brick at random open cells. Budget
        // instead of fill-chance is what makes the knob honest: it bounds the
        // board's total hit points, so "how long does a board take" scales
        // predictably even though every layout differs. Mirrored cells cost
        // double — symmetry buys looks, not free bricks.
        int stalls = 0; // random placement can stall once the grid fills up
        while (tierBudget > 0 && stalls < 200)
        {
            int row = rng.Next(rows);
            int col = rng.Next(HalfColumns);
            if (grid[row, col] != '.')
            {
                stalls++;
                continue;
            }

            // Stronger bricks live near the top, like the hand-made boards
            // (and 1976's score-by-row): depth maps to the row's tier ceiling.
            int rowTierCap = 1 + (tierCap - 1) * (rows - 1 - row) / Math.Max(1, rows - 1);
            int tier = 1 + rng.Next(rowTierCap);

            int mirror = Columns - 1 - col;
            grid[row, col] = (char)('0' + tier);
            grid[row, mirror] = (char)('0' + tier); // same cell when col is the center
            tierBudget -= tier * (mirror == col ? 1 : 2);
        }

        // Unbreakables go in *after* the budget is spent, only into leftover
        // holes — they are obstacles to route around, never a substitute for
        // bricks to clear (LevelCleared ignores them, so they can't strand a
        // board unwinnable).
        for (int row = 0; row < rows; row++)
            for (int col = 0; col < HalfColumns; col++)
                if (grid[row, col] == '.' && rng.NextDouble() < unbreakableDensity)
                {
                    grid[row, col] = 'X';
                    grid[row, Columns - 1 - col] = 'X';
                }

        // Render to the text format — including a comment line, because the
        // parser skips those. The format is the contract; everything the
        // loader tolerates, the generator may emit.
        var text = new StringBuilder();
        text.Append("# generated board ").Append(boardNumber + 1).Append('\n');
        for (int row = 0; row < rows; row++)
        {
            for (int col = 0; col < Columns; col++)
                text.Append(grid[row, col]);
            text.Append('\n');
        }
        return text.ToString();
    }
}
