using Clong.Core.Domain.Enum;
using Clong.Core.Ports.Driven;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Vector2 = Microsoft.Xna.Framework.Vector2;

namespace Clong.Kni.Adapter.Driven.Rendering;

public class Renderer(SpriteBatch spriteBatch, TextureMap textureMap, SpriteFont font) : IForRendering
{
    public void DrawTexture(TextureId texture, System.Numerics.Vector2 position)
    {
        var texture2D = textureMap[texture];

        spriteBatch.Draw(
            texture2D,
            new Vector2(position.X, position.Y),
            null,
            Color.White,
            0,
            new Vector2(texture2D.Width / 2f, texture2D.Height / 2f),
            Vector2.One,
            SpriteEffects.None,
            0f
        );
    }

    public void DrawString(string text, System.Numerics.Vector2 position, float scale = 1f, bool alignCentered = true)
    {
        var origin = alignCentered ? font.MeasureString(text) / 2 : Vector2.Zero;

        spriteBatch.DrawString(
            font,
            text,
            new Vector2(position.X, position.Y),
            Color.White,
            0,
            new Vector2(origin.X, origin.Y),
            Vector2.One * scale,
            SpriteEffects.None,
            0f
        );
    }
}