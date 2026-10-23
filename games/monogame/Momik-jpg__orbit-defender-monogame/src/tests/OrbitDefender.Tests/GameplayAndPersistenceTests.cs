using Microsoft.Xna.Framework;
using OrbitDefender.Models;
using OrbitDefender.Services;
using Xunit;

namespace OrbitDefender.Tests;

public sealed class GameplayAndPersistenceTests
{
    [Fact]
    public void HasPassedBottom_WhenAsteroidLeavesSide_ReturnsFalse()
    {
        var asteroid = new Asteroid(new Vector2(-100, 100), Vector2.Zero, 20, 10);

        Assert.False(asteroid.HasPassedBottom(new Rectangle(0, 0, 800, 600)));
    }

    [Fact]
    public void Record_WhenTargetCannotBeWritten_ReturnsFalse()
    {
        var directory = Path.Combine(Path.GetTempPath(), $"orbit-tests-{Guid.NewGuid():N}");
        Directory.CreateDirectory(directory);

        try
        {
            var service = new HighScoreService(directory);

            Assert.False(service.Record("Pilot", 100, 1));
        }
        finally
        {
            Directory.Delete(directory, recursive: true);
        }
    }
}
