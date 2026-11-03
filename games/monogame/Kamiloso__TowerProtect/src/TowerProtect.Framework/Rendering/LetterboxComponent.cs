using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using static TowerProtect.Domain.Config.ScreenConfig;

namespace TowerProtect.Framework.Rendering;

internal class LetterboxComponent(Game game) : DrawableGameComponent(game)
{
    private SpriteBatch _spriteBatch = null!;
    private Texture2D _pixel = null!;

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _pixel = new Texture2D(GraphicsDevice, 1, 1);
        _pixel.SetData([Color.Black]);

        base.LoadContent();
    }

    public override void Draw(GameTime gameTime)
    {
        int width = GraphicsDevice.Viewport.Width;
        int height = GraphicsDevice.Viewport.Height;
        float currentRatio = (float)width / height;

        if (currentRatio < MinAspectRatio || currentRatio > MaxAspectRatio)
        {
            _spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.Opaque);

            if (currentRatio > MaxAspectRatio)
            {
                int targetWidth = (int)(height * MaxAspectRatio);
                int boxWidth = (width - targetWidth) / 2;

                _spriteBatch.Draw(_pixel, new Rectangle(boxWidth - width, 0, width, height), Color.Black);
                _spriteBatch.Draw(_pixel, new Rectangle(width - boxWidth, 0, width, height), Color.Black);
            }
            else if (currentRatio < MinAspectRatio)
            {
                int targetHeight = (int)(width / MinAspectRatio);
                int boxHeight = (height - targetHeight) / 2;

                _spriteBatch.Draw(_pixel, new Rectangle(0, boxHeight - height, width, height), Color.Black);
                _spriteBatch.Draw(_pixel, new Rectangle(0, height - boxHeight, width, height), Color.Black);
            }

            _spriteBatch.End();
        }

        base.Draw(gameTime);
    }
}
