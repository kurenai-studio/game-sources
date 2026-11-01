using System.Drawing;
using System.Numerics;
using Clong.Core.Domain.Const;
using Clong.Core.Domain.Dto;
using Clong.Core.Domain.Enum;
using Clong.Core.Domain.Input;
using Clong.Core.Ports.Driven;

namespace Clong.Core.Domain.Entity;

internal class Paddle
{
    private readonly Size _size = new(16, 64);
    private const float Speed = 500f;

    public required TextureId Texture { get; init; }
    public Vector2 Position { get; set; }

    public Rectangle BoundingBox =>
        new(
            (int)Position.X - _size.Width / 2,
            (int)Position.Y - _size.Height / 2,
            _size.Width,
            _size.Height
        );

    public void Update(GameTime gameTime, InGameControlInput input)
    {
        var newPositionY = Position.Y + gameTime.DeltaSeconds * Speed * input.Y;
        var clampedPositionY = Math.Clamp(
            newPositionY,
            _size.Height / 2f,
            Resolution.DesignHeight - _size.Height / 2f
        );

        Position = Position with { Y = clampedPositionY };
    }

    public void Draw(IForRendering renderer)
    {
        renderer.DrawTexture(Texture, Position);
    }
}