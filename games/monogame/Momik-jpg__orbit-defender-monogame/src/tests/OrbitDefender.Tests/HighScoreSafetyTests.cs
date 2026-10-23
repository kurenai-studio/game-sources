using OrbitDefender.Services;
using Xunit;

namespace OrbitDefender.Tests;

public sealed class HighScoreSafetyTests : IDisposable
{
    private readonly string _directory = Path.Combine(Path.GetTempPath(), $"orbit-safety-{Guid.NewGuid():N}");
    private string FilePath => Path.Combine(_directory, "highscores.json");

    public HighScoreSafetyTests() => Directory.CreateDirectory(_directory);

    [Theory]
    [InlineData("{broken")]
    [InlineData("")]
    [InlineData("null")]
    [InlineData("[null]")]
    [InlineData("[{\"PlayerName\":\"Pilot\",\"Score\":0}]")]
    [InlineData("[{\"PlayerName\":\"Pilot\",\"Score\":-1}]")]
    [InlineData("[{\"PlayerName\":\"   \",\"Score\":100}]")]
    [InlineData("[{\"PlayerName\":\"First\",\"Score\":200},{\"PlayerName\":null,\"Score\":100}]")]
    public void Record_WhenDataIsInvalid_PreservesOriginalFile(string original)
    {
        File.WriteAllText(FilePath, original);
        var service = new HighScoreService(FilePath);

        Assert.Empty(service.Load());
        Assert.False(service.Record("Pilot", 100, 1));
        Assert.Equal(original, File.ReadAllText(FilePath));
        Assert.Empty(Directory.GetFiles(_directory, "*.tmp"));

        File.WriteAllText(FilePath, "[]");
        Assert.True(service.Record("Pilot", 100, 1));
        Assert.Equal(100, Assert.Single(service.Load()).Score);
    }

    [Fact]
    public void Record_WhenFileIsMissing_CreatesStoreAndKeepsEarlierScores()
    {
        var service = new HighScoreService(FilePath);

        Assert.True(service.Record("First", 100, 1));
        Assert.True(service.Record("Second", 200, 2));
        var scores = service.Load();

        Assert.Equal(2, scores.Count);
        Assert.Equal("Second", scores[0].PlayerName);
        Assert.Equal("First", scores[1].PlayerName);
    }

    [Fact]
    public void Record_WhenFileIsLocked_DoesNotReplaceIt()
    {
        File.WriteAllText(FilePath, "[]");
        var service = new HighScoreService(FilePath);
        using (var locked = new FileStream(FilePath, FileMode.Open, FileAccess.ReadWrite, FileShare.None))
        {
            Assert.False(service.Record("Pilot", 100, 1));
        }

        Assert.Equal("[]", File.ReadAllText(FilePath));
        Assert.True(service.Record("Pilot", 100, 1));
    }

    public void Dispose() => Directory.Delete(_directory, recursive: true);
}
