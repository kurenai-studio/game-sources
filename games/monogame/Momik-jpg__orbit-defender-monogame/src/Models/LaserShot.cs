using Microsoft.Xna.Framework;
using OrbitDefender.Core;

namespace OrbitDefender.Models;

public sealed class LaserShot
{
    private const float WidthValue = 6f;
    private const float HeightValue = 18f;

    public LaserShot(Vector2 startPosition)
    {
        Position = startPosition;
    }

    public Vector2 Position { get; private set; }
    public float Width => WidthValue;
    public float Height => HeightValue;
    public float Radius => WidthValue * 0.85f;

    public void Update(float deltaSeconds)
    {
        Position = new Vector2(Position.X, Position.Y - (GameSettings.ShotSpeed * deltaSeconds));
    }

    public bool IsOutOfBounds(Rectangle playBounds)
    {
        return Position.Y + Height < playBounds.Top;
    }
}
