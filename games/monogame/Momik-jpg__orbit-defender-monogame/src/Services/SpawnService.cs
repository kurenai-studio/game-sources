using Microsoft.Xna.Framework;
using OrbitDefender.Core;
using OrbitDefender.Models;

namespace OrbitDefender.Services;

public sealed class SpawnService : ISpawnService
{
    private readonly Random _random;

    public SpawnService(Random? random = null)
    {
        _random = random ?? new Random();
    }

    public Asteroid CreateAsteroid(GameSession session, Rectangle playBounds)
    {
        var size = RandomRange(30f, 82f);
        var spawnX = RandomRange(playBounds.Left + (size * 0.55f), playBounds.Right - (size * 0.55f));
        var spawnY = playBounds.Top - size;

        var fallSpeed = (GameSettings.BaseAsteroidSpeed * session.AsteroidSpeedMultiplier) + RandomRange(25f, 95f);
        var horizontalDrift = RandomRange(-70f, 70f) + ((session.Level - 1) * 3.2f * RandomSign());
        var scoreValue = (int)MathF.Round(14f + (size * 0.58f) + ((session.Level - 1) * 4f));

        return new Asteroid(
            new Vector2(spawnX, spawnY),
            new Vector2(horizontalDrift, fallSpeed),
            size,
            scoreValue);
    }

    public void PopulateStars(ICollection<Star> stars, Rectangle playBounds)
    {
        stars.Clear();

        for (var index = 0; index < GameSettings.StarCount; index++)
        {
            stars.Add(CreateStar(playBounds, randomY: true));
        }
    }

    public void RecycleStar(Star star, Rectangle playBounds)
    {
        var replacement = CreateStar(playBounds, randomY: false);
        star.Position = replacement.Position;
        star.Speed = replacement.Speed;
        star.Size = replacement.Size;
        star.Brightness = replacement.Brightness;
    }

    private Star CreateStar(Rectangle playBounds, bool randomY)
    {
        var x = RandomRange(playBounds.Left + 2, playBounds.Right - 2);
        var y = randomY
            ? RandomRange(playBounds.Top, playBounds.Bottom)
            : RandomRange(playBounds.Top - 120, playBounds.Top - 4);

        var speed = RandomRange(20f, 110f);
        var size = RandomRange(1f, 3f);
        var brightness = RandomRange(0.35f, 0.92f);

        return new Star(new Vector2(x, y), speed, size, brightness);
    }

    private float RandomRange(float minimum, float maximum)
    {
        return minimum + (_random.NextSingle() * (maximum - minimum));
    }

    private int RandomSign()
    {
        return _random.Next(0, 2) == 0 ? -1 : 1;
    }
}
