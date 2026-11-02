using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Breakout.Entities;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// A generator is the rare game system that is *fully* unit-testable: pure
/// input (a seeded Random and a board number), pure output (text). These
/// tests pin the three properties everything else relies on — determinism
/// (replays re-roll the same boards), the format contract (the parser can
/// always read it), and winnability (there is always something to clear).
/// </summary>
public class BoardGeneratorTests
{
    [Fact]
    public void Generate_IsDeterministicForASeed()
    {
        for (int board = 0; board < 12; board++)
            Assert.Equal(
                BoardGenerator.Generate(new Random(42), board),
                BoardGenerator.Generate(new Random(42), board));
    }

    [Fact]
    public void Generate_DifferentSeedsGiveDifferentBoards()
        => Assert.NotEqual(
            BoardGenerator.Generate(new Random(1), 5),
            BoardGenerator.Generate(new Random(2), 5));

    [Fact]
    public void Generate_OutputAlwaysParsesAndIsWinnable()
    {
        for (int seed = 0; seed < 50; seed++)
            for (int board = 0; board < 15; board++)
            {
                string text = BoardGenerator.Generate(new Random(seed), board);
                List<Brick> bricks = LevelLoader.Parse(new StringReader(text));

                Assert.NotEmpty(bricks);
                // LevelCleared means "only unbreakables remain" — a board of
                // pure unbreakables would clear itself instantly (or worse,
                // never need clearing). There must be real work on it.
                Assert.Contains(bricks, b => !b.IsUnbreakable);
            }
    }

    [Fact]
    public void Generate_EmitsOnlyContractCharacters()
    {
        string text = BoardGenerator.Generate(new Random(7), 10);
        foreach (string line in Lines(text).Skip(1)) // line 0 is the comment
            Assert.All(line, c => Assert.True(
                c == '.' || c == 'X' || (c >= '1' && c <= '5'),
                $"unexpected character '{c}'"));
    }

    [Fact]
    public void Generate_BoardsAreMirrored()
    {
        for (int seed = 0; seed < 20; seed++)
        {
            string text = BoardGenerator.Generate(new Random(seed), 6);
            foreach (string line in Lines(text).Skip(1))
                Assert.Equal(line, new string(line.Reverse().ToArray()));
        }
    }

    [Fact]
    public void Generate_RowCountStaysOnScreen()
    {
        // 8 rows is the cap — beyond it the wall crowds the paddle.
        string text = BoardGenerator.Generate(new Random(3), 100);
        Assert.InRange(Lines(text).Skip(1).Count(), 1, 8);
    }

    private static IEnumerable<string> Lines(string text)
        => text.Split('\n', StringSplitOptions.RemoveEmptyEntries);
}
