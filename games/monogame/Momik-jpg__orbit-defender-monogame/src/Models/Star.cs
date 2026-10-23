using Microsoft.Xna.Framework;

namespace OrbitDefender.Models;

public sealed class Star
{
    public Star(Vector2 position, float speed, float size, float brightness)
    {
        Position = position;
        Speed = speed;
        Size = size;
        Brightness = brightness;
    }

    public Vector2 Position { get; set; }
    public float Speed { get; set; }
    public float Size { get; set; }
    public float Brightness { get; set; }

    public void Update(float deltaSeconds)
    {
        Position = new Vector2(Position.X, Position.Y + (Speed * deltaSeconds));
    }

    public bool PassedBottom(Rectangle playBounds)
    {
        return Position.Y > playBounds.Bottom + 2;
    }
}
