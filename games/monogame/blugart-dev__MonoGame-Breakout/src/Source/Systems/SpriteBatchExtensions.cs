using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Breakout.Systems;

/// <summary>
/// MonoGame has no built-in "draw a rectangle" or "draw centered text" —
/// SpriteBatch draws *textures*, full stop. The standard idiom is a 1x1 white
/// texture stretched and tinted per draw call: sampled at any size it yields
/// flat white, and the tint color does the rest. The GPU does not care that
/// the source texture is a single pixel. Every solid shape in this game is
/// this one texture.
/// </summary>
public static class SpriteBatchExtensions
{
    private static Texture2D _pixel;

    /// <summary>Must be called once after the GraphicsDevice exists (LoadContent).</summary>
    public static void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    public static void DrawRect(this SpriteBatch spriteBatch, Rectangle rect, Color color)
        => spriteBatch.Draw(_pixel, rect, color);

    public static void DrawCenteredText(this SpriteBatch spriteBatch, SpriteFont font,
        string text, Vector2 center, Color color, float scale = 1f)
    {
        Vector2 size = font.MeasureString(text) * scale;
        spriteBatch.DrawShadowedText(font, text, center - size / 2f, color, scale);
    }

    /// <summary>
    /// Text with a drop shadow. SpriteFont has no outline or shadow support —
    /// the standard idiom is simply drawing the string twice: a dark copy
    /// offset down-right, then the real one on top. Over a dark background the
    /// shadow disappears; over a bright brick it keeps the glyphs legible.
    /// Every piece of text in this game routes through here, because almost
    /// all of it can end up on top of a busy playfield.
    /// </summary>
    public static void DrawShadowedText(this SpriteBatch spriteBatch, SpriteFont font,
        string text, Vector2 position, Color color, float scale = 1f)
    {
        // Offset scales with the text so big banners get proportionally
        // heavier shadows instead of a hairline.
        var offset = new Vector2(MathHelper.Max(1f, 2f * scale));
        spriteBatch.DrawString(font, text, position + offset, Color.Black * 0.8f,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        spriteBatch.DrawString(font, text, position, color,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
    }
}
