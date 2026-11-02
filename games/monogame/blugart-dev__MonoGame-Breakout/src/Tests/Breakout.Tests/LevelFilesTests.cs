using System;
using System.Collections.Generic;
using System.IO;
using Breakout.Entities;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// The shipped boards, parsed exactly as the game parses them. The
/// generator's output is tested against the format contract; the hand-made
/// files deserve the same — a typo'd character or an accidentally
/// unwinnable board in level03.txt would otherwise only be caught by
/// playing that far. The .txt files are linked into the test output by the
/// test csproj, the same CopyToOutputDirectory trick the game csproj uses.
/// </summary>
public class LevelFilesTests
{
    private static string[] LevelFiles
        => Directory.GetFiles(Path.Combine(AppContext.BaseDirectory, "Levels"), "level*.txt");

    [Fact]
    public void ShippedLevels_MatchTheSessionsLevelCount()
        => Assert.Equal(GameSession.LevelCount, LevelFiles.Length);

    [Fact]
    public void ShippedLevels_ParseNonEmptyAndWinnable()
    {
        foreach (string path in LevelFiles)
        {
            using StreamReader reader = File.OpenText(path);
            List<Brick> bricks = LevelLoader.Parse(reader);

            Assert.NotEmpty(bricks);
            // LevelCleared ignores unbreakables, so a board needs at least
            // one breakable brick or there is nothing to clear.
            Assert.Contains(bricks, b => !b.IsUnbreakable);
        }
    }

    [Fact]
    public void ShippedLevels_StayClearOfThePaddleRow()
    {
        foreach (string path in LevelFiles)
        {
            using StreamReader reader = File.OpenText(path);
            foreach (Brick brick in LevelLoader.Parse(reader))
                Assert.True(brick.Bounds.Bottom < Paddle.DefaultY,
                    $"{Path.GetFileName(path)} reaches the paddle row");
        }
    }
}
