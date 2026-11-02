using System.Collections.Generic;
using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// Only the pure ranking core is tested — Record/Load/Save touch a real file
/// under ApplicationData, which a test must never do (it would corrupt the
/// developer's actual high scores, and CI machines shouldn't write profile
/// data at all). That boundary is why InsertScore exists as its own method.
/// </summary>
public class HighScoresTests
{
    [Fact]
    public void InsertScore_FirstScoreTakesRankZero()
    {
        var scores = new List<int>();
        Assert.Equal(0, HighScores.InsertScore(scores, 100));
        Assert.Equal(new[] { 100 }, scores);
    }

    [Fact]
    public void InsertScore_RanksDescendingWithTiesKeepingTheIncumbent()
    {
        var scores = new List<int> { 300, 200, 100 };

        Assert.Equal(1, HighScores.InsertScore(scores, 250));
        // An equal score does NOT outrank the earlier run (strict >).
        Assert.Equal(3, HighScores.InsertScore(scores, 200));
        Assert.Equal(new[] { 300, 250, 200, 200, 100 }, scores);
    }

    [Fact]
    public void InsertScore_TableHoldsFiveAndDropsTheLowest()
    {
        var scores = new List<int> { 500, 400, 300, 200, 100 };

        Assert.Equal(2, HighScores.InsertScore(scores, 350));
        Assert.Equal(5, scores.Count);
        Assert.DoesNotContain(100, scores);
    }

    [Fact]
    public void InsertScore_RejectsWhatDoesNotPlace()
    {
        var scores = new List<int> { 500, 400, 300, 200, 100 };

        Assert.Equal(-1, HighScores.InsertScore(scores, 50)); // below a full table
        Assert.Equal(-1, HighScores.InsertScore(scores, 0));  // scoring nothing never places
        Assert.Equal(new[] { 500, 400, 300, 200, 100 }, scores);
    }
}
