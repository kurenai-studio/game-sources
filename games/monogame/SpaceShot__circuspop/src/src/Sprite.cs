using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace CircusPop;

public class Sprite : IMovingObject
{
    public Texture2D Texture { 
        get;  
        set { field = value; }
    }
    public Vector2 Position;
    public Vector2 Velocity;

    public Sprite()
    {
        Position = Vector2.Zero;
        Velocity = Vector2.Zero;
    }
    public Sprite(Vector2 initialPosition, Vector2 initialVelocity)
    {
        Position = initialPosition;
        Velocity = initialVelocity;
    }

    Vector2 IMovingObject.Position => Position;
    Vector2 IMovingObject.Velocity => Velocity;
    public int Width => Texture.Width;
    public int Height => Texture.Height;
}
