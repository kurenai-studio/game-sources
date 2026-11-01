using System.Drawing;
using System.Numerics;
using Clong.Core.Domain.Dto;
using Clong.Core.Domain.Enum;
using Clong.Core.Ports.Driven;

namespace Clong.Core.Domain.Entity;

internal class Ball
{
    private const TextureId Texture = TextureId.Ball;
    private const float RotationSpeed = 1.5f;
    private Vector2 _pullDirection = new(0, 1f);

    public Size Size { get; } = new(16, 16);
    public Vector2 Position { get; set; }
    public Vector2 Direction { get; set; }
    public float Speed { get; set; } = 600f;

    public Rectangle BoundingBox =>
        new(
            (int)Position.X - Size.Width / 2,
            (int)Position.Y - Size.Height / 2,
            Size.Width,
            Size.Height
        );

    public void Update(GameTime gameTime)
    {
        RotatePullDirection(gameTime);
        Direction += _pullDirection * gameTime.DeltaSeconds;
        Position += Speed * Direction * gameTime.DeltaSeconds;
    }

    private void RotatePullDirection(GameTime gameTime)
    {
        _pullDirection = Vector2.Transform(_pullDirection, Matrix4x4.CreateRotationZ(RotationSpeed * gameTime.DeltaSeconds));
        _pullDirection = Vector2.Normalize(_pullDirection);
    }

    public void Draw(IForRendering renderer)
    {
        renderer.DrawTexture(Texture, Position);
    }
}