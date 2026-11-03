using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Common;
using Snake.Core.Graphics;
using System;
using System.IO;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays the background image.
    /// </summary>
    public class BackgroundScreen : GameScreen
    {
        /// <summary>
        /// The background texture path.
        /// </summary>
        private readonly string BackgroundTexturePath = Path.Combine("Backgrounds", "background_dark");

        /// <summary>
        /// The content manager.
        /// </summary>
        private ContentManager contentManager;

        /// <summary>
        /// The background sprite.
        /// </summary>
        private Sprite backgroundSprite;

        /// <summary>
        /// Initializes a new instance of the BackgroundScreen class.
        /// </summary>
        public BackgroundScreen()
        {
            TransitionOnTime = TimeSpan.FromSeconds(DefaultTransitionTime);
            TransitionOffTime = TimeSpan.FromSeconds(DefaultTransitionTime);
        }

        /// <summary>
        /// Loads the background content.
        /// </summary>
        public override void LoadContent()
        {
            base.LoadContent();

            contentManager ??= new ContentManager(ScreenManager.Game.Services, "Content");

            Texture2D backgroundTexture = contentManager.Load<Texture2D>(BackgroundTexturePath);
            TextureRegion backgroundRegion = new TextureRegion(
                backgroundTexture,
                0,
                0,
                backgroundTexture.Width,
                backgroundTexture.Height
            );
            backgroundSprite = new Sprite(backgroundRegion);
        }

        /// <summary>
        /// Unloads the background content.
        /// </summary>
        public override void UnloadContent()
        {
            contentManager?.Unload();
            base.UnloadContent();
        }

        /// <summary>
        /// Updates the background screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="otherScreenHasFocus">Whether another screen has focus.</param>
        /// <param name="coveredByOtherScreen">Whether this screen is covered by another screen.</param>
        public override void Update(GameTime gameTime, bool otherScreenHasFocus, bool coveredByOtherScreen)
        {
            base.Update(gameTime, otherScreenHasFocus, false);
        }

        /// <summary>
        /// Draws the background screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(GameTime gameTime)
        {
            ScreenManager.GraphicsDevice.Clear(ClearOptions.Target, Color.Black, 0, 0);

            SpriteBatch spriteBatch = ScreenManager.SpriteBatch;

            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, ScreenManager.GlobalTransformation);

            backgroundSprite.Position = Helper.GetCenterScreenVector2(
                ScreenManager.GraphicsDevice.Viewport,
                backgroundSprite.Region
            );
            backgroundSprite.Draw(spriteBatch);

            spriteBatch.End();
        }
    }
}
