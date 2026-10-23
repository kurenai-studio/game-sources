using Microsoft.Xna.Framework;
using OrbitDefender.Core;

namespace OrbitDefender.Models;

public sealed class PlayerShip
{
    private float _shotCooldownRemaining;

    public PlayerShip(Vector2 startPosition)
    {
        Position = startPosition;
    }

    public Vector2 Position { get; private set; }

    public float Width => GameSettings.PlayerWidth;
    public float Height => GameSettings.PlayerHeight;
    public float Radius => Width * 0.42f;

    public float CooldownRatio =>
        _shotCooldownRemaining <= 0
            ? 1f
            : 1f - MathF.Min(1f, _shotCooldownRemaining / GameSettings.ShotCooldownSeconds);

    public void Update(float deltaSeconds, Vector2 movementDirection, Rectangle playBounds)
    {
        if (movementDirection != Vector2.Zero)
        {
            movementDirection.Normalize();
        }

        Position += movementDirection * GameSettings.PlayerSpeed * deltaSeconds;

        var clampedX = MathHelper.Clamp(Position.X, playBounds.Left + (Width * 0.5f), playBounds.Right - (Width * 0.5f));
        var clampedY = MathHelper.Clamp(Position.Y, playBounds.Top + (Height * 0.5f), playBounds.Bottom - (Height * 0.5f));
        Position = new Vector2(clampedX, clampedY);

        _shotCooldownRemaining = Math.Max(0, _shotCooldownRemaining - deltaSeconds);
    }

    public LaserShot? TryShoot()
    {
        if (_shotCooldownRemaining > 0)
        {
            return null;
        }

        _shotCooldownRemaining = GameSettings.ShotCooldownSeconds;
        var startPosition = new Vector2(Position.X, Position.Y - (Height * 0.68f));
        return new LaserShot(startPosition);
    }
}
