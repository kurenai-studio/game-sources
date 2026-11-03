using Microsoft.Xna.Framework.Graphics;

namespace TowerProtect.Framework.Rendering.Model;

internal readonly record struct MonoSprite(
    Texture2D Texture,
    RectangleF TextureArea,
    float DepthLayer,
    float Rotation)
{
    public Vector2 Origin { get; } = new(Texture.Width / 2f, Texture.Height / 2f);

    public Vector2 Scale { get; } = new(
        TextureArea.Width / Texture.Width,
        TextureArea.Height / Texture.Height
    );

    public Vector2 CenterPosition { get; } = new(
        TextureArea.X + TextureArea.Width / 2f,
        TextureArea.Y + TextureArea.Height / 2f
    );
}
