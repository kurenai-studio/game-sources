using System;
using System.Numerics;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended.Graphics;
using PortalMercenary.Graphics;
using Vector2 = Microsoft.Xna.Framework.Vector2;

namespace PortalMercenary.Game;

public class Slice
{
    private readonly CuttingSprite _sprite;
    private Vector2 _position;
    private Vector2 _impulse;
    private float _height;
    private float _rotation;

    public Slice(CuttingSprite sprite, Vector2 position, Vector2 impulse, float height)
    {
        _sprite = sprite;
        _position = position;
        _impulse = impulse;
        _height = height;
    }

    private const float Gravity = 200f;

    public void Update(float dt)
    {
        _position += _impulse * dt;

        if  (_height < 0)
        {
            _impulse.Y = 0;
            _rotation += _impulse.X * dt / (2 * MathF.PI);
            _impulse.X -= _impulse.X * dt * .5f;
        }
        else
        {
            _height -= _impulse.Y * dt;
            _impulse.Y += Gravity * dt;
        }
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        _sprite.Draw(spriteBatch,  _position, _rotation, Vector2.One);
    }
}