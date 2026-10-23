using Microsoft.Xna.Framework;
using OrbitDefender.Core;
using OrbitDefender.Models;
using OrbitDefender.Services;
using Xunit;

namespace OrbitDefender.Tests;

public sealed class SpawnServiceTests
{
    private static readonly Rectangle Bounds = new(100, 50, 1000, 600);

    [Fact]
    public void SameSeed_ReproducesAsteroids()
    {
        var first = new SpawnService(new Random(1234));
        var second = new SpawnService(new Random(1234));
        var session = new GameSession();
        session.Reset();

        for (var index = 0; index < 100; index++)
        {
            var a = first.CreateAsteroid(session, Bounds);
            var b = second.CreateAsteroid(session, Bounds);
            Assert.Equal(a.Position, b.Position);
            Assert.Equal(a.Velocity, b.Velocity);
            Assert.Equal(a.Size, b.Size);
            Assert.Equal(a.ScoreValue, b.ScoreValue);
            Assert.True(a.Position.X - a.Radius >= Bounds.Left);
            Assert.True(a.Position.X + a.Radius <= Bounds.Right);
            Assert.Equal(Bounds.Top - a.Size, a.Position.Y);
        }
    }

    [Fact]
    public void HigherLevel_IncreasesSpeedAndScore_ForSameRandomSequence()
    {
        var lower = new GameSession();
        lower.Reset();
        var higher = new GameSession();
        higher.Reset();
        higher.AddScore(GameSettings.LevelScoreStep * 4);
        var lowSpawn = new SpawnService(new Random(42));
        var highSpawn = new SpawnService(new Random(42));

        for (var index = 0; index < 100; index++)
        {
            var a = lowSpawn.CreateAsteroid(lower, Bounds);
            var b = highSpawn.CreateAsteroid(higher, Bounds);
            Assert.Equal(a.Size, b.Size);
            Assert.True(b.Velocity.Y > a.Velocity.Y);
            Assert.Equal(a.ScoreValue + 16, b.ScoreValue);
        }
    }

    [Fact]
    public void Stars_AreReproducible_AndRecycleAbovePlayArea()
    {
        var first = new SpawnService(new Random(17));
        var second = new SpawnService(new Random(17));
        var stars = new List<Star>();
        var matching = new List<Star>();
        first.PopulateStars(stars, Bounds);
        second.PopulateStars(matching, Bounds);

        Assert.Equal(GameSettings.StarCount, stars.Count);
        for (var index = 0; index < stars.Count; index++)
        {
            var star = stars[index];
            Assert.Equal(matching[index].Position, star.Position);
            Assert.InRange(star.Position.Y, Bounds.Top, Bounds.Bottom);
            AssertStarRanges(star);
            first.RecycleStar(star, Bounds);
            second.RecycleStar(matching[index], Bounds);
            Assert.Equal(matching[index].Position, star.Position);
            Assert.InRange(star.Position.Y, Bounds.Top - 120, Bounds.Top - 4);
            AssertStarRanges(star);
        }

        first.PopulateStars(stars, Bounds);
        Assert.Equal(GameSettings.StarCount, stars.Count);
    }

    [Fact]
    public void DefaultRandom_ProducesValidAsteroid()
    {
        var session = new GameSession();
        session.Reset();
        var asteroid = new SpawnService().CreateAsteroid(session, Bounds);
        Assert.InRange(asteroid.Size, 30f, 82f);
        Assert.True(asteroid.Position.X - asteroid.Radius >= Bounds.Left);
        Assert.True(asteroid.Position.X + asteroid.Radius <= Bounds.Right);
        Assert.True(asteroid.Velocity.Y > GameSettings.BaseAsteroidSpeed);
    }

    private static void AssertStarRanges(Star star)
    {
        Assert.InRange(star.Position.X, Bounds.Left + 2, Bounds.Right - 2);
        Assert.InRange(star.Speed, 20f, 110f);
        Assert.InRange(star.Size, 1f, 3f);
        Assert.InRange(star.Brightness, 0.35f, 0.92f);
    }
}
