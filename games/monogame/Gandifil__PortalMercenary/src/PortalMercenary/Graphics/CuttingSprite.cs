using System;
using Microsoft.Xna.Framework;
using MonoGame.Extended.Graphics;

namespace PortalMercenary.Graphics;

public class CuttingSprite: Sprite
{
    public bool IsСut {get; private set; }
    
    public CuttingSprite(Sprite source) : base(source)
    {
        Color = Color.Black; // отображает спрайт полностью
    }

    public enum Direction
    {
        Up, // 1
        Down, // 0
    }

    public void Cut(Direction direction)
    {
        U = (TextureRegion.LeftUV + TextureRegion.RightUV) / 2;
        V = (TextureRegion.TopUV + TextureRegion.BottomUV) / 2;
        Cut(U, V, Random.Shared.NextSingle(), direction);
    }

    private void Cut(float u, float v, float angle, Direction direction)
    {
        U = u;
        V = v;
        Angle = angle;
        _direction = direction;
        Color = new Color(U, V, Angle, direction == Direction.Up ? 1 : 0);
        IsСut = true;
    }
    
    private float U;
        
    private float V;
        
    private float Angle;

    private Direction _direction;

    public CuttingSprite GetReversed()
    {
        var sprite = new CuttingSprite(this);
        sprite.Cut(U, V, Angle, _direction == Direction.Up ? Direction.Down : Direction.Up);
        return sprite;
    }
}