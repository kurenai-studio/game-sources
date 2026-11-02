using System.Collections.Generic;
using System.IO;
using Breakout.Entities;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// The grid format is a contract with two producers (files, the generator)
/// and one consumer — so the parser gets tested against the contract, fed
/// from a StringReader. No file IO in sight: that's what the Load/Parse
/// split bought.
/// </summary>
public class LevelLoaderTests
{
    private static List<Brick> Parse(string text)
        => LevelLoader.Parse(new StringReader(text));

    [Fact]
    public void Parse_ReadsTiersUnbreakablesAndGaps()
    {
        List<Brick> bricks = Parse("#comment\n.1.\nX25\n");

        Assert.Equal(4, bricks.Count);
        Assert.Single(bricks, b => b.IsUnbreakable);

        Brick tier1 = bricks[0];
        Assert.Equal(1, tier1.HitPoints);
        Assert.Equal(10, tier1.ScoreValue); // tier x 10

        Brick tier5 = bricks[^1];
        Assert.Equal(5, tier5.HitPoints);
        Assert.Equal(50, tier5.ScoreValue);
    }

    [Fact]
    public void Parse_CommentsAndBlankLinesDoNotAdvanceTheGrid()
    {
        // Two brick rows separated by noise must land on adjacent rows.
        List<Brick> noisy = Parse("# header\n1\n\n# mid\n1\n");
        List<Brick> plain = Parse("1\n1\n");

        Assert.Equal(plain.Count, noisy.Count);
        for (int i = 0; i < plain.Count; i++)
            Assert.Equal(plain[i].Bounds, noisy[i].Bounds);
    }

    [Fact]
    public void Parse_IgnoresColumnsBeyondTheGrid()
    {
        // 13 columns is the contract; a longer line must not overflow it.
        string line = new string('1', 20);
        Assert.Equal(13, Parse(line).Count);
    }

    [Fact]
    public void Parse_BricksDoNotOverlap()
    {
        List<Brick> bricks = Parse("1111111111111\n11111111111111\n");
        for (int a = 0; a < bricks.Count; a++)
            for (int b = a + 1; b < bricks.Count; b++)
                Assert.False(bricks[a].Bounds.Intersects(bricks[b].Bounds));
    }

    [Fact]
    public void Parse_UnknownCharactersAreEmptyCells()
        => Assert.Empty(Parse("9?ab\n"));
}
