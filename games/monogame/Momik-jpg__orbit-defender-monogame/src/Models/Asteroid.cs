using Microsoft.Xna.Framework;

namespace OrbitDefender.Models;

public sealed class Asteroid
{
    public Asteroid(Vector2 startPosition, Vector2 velocity, float size, int scoreValue)
    {
        Position = startPosition;
        Velocity = velocity;
        Size = size;
        ScoreValue = scoreValue;
    }

    public Vector2 Position { get; private set; }
    public Vector2 Velocity { get; }
    public float Size { get; }
    public int ScoreValue { get; }
    public float Radius => Size * 0.45f;

    public void Update(float deltaSeconds)
    {
        Position += Velocity * deltaSeconds;
    }

    public bool HasPassedBottom(Rectangle playBounds)
    {
        return Position.Y - Size > playBounds.Bottom + 10;
    }

    public bool HasLeftHorizontalBounds(Rectangle playBounds)
    {
        return Position.X + Size < playBounds.Left - 20
            || Position.X - Size > playBounds.Right + 20;
    }
}
