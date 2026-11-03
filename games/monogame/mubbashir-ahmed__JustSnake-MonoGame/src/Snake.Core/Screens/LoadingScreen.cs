using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Enums;
using Snake.Core.Graphics;
using Snake.Core.Localization;
using Snake.Core.Managers;
using System;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays while loading other screens.
    /// </summary>
    public class LoadingScreen : GameScreen
    {
        /// <summary>
        /// The default transition on time seconds.
        /// </summary>
        private const double DefaultTransitionOnTime = 0.5;

        /// <summary>
        /// The single screen count.
        /// </summary>
        private const int SingleScreenCount = 1;

        /// <summary>
        /// Whether loading is slow and should show a message.
        /// </summary>
        private readonly bool loadingIsSlow;

        /// <summary>
        /// Whether other screens are gone.
        /// </summary>
        private bool otherScreensAreGone;

        /// <summary>
        /// The screens to load.
        /// </summary>
        private readonly GameScreen[] screensToLoad;

        /// <summary>
        /// The loading text.
        /// </summary>
        private readonly Text loadingText;

        /// <summary>
        /// Initializes a new instance of the LoadingScreen class.
        /// </summary>
        /// <param name="loadingIsSlow">Whether loading is slow and should show a message.</param>
        /// <param name="screensToLoad">The screens to load.</param>
        private LoadingScreen(bool loadingIsSlow, GameScreen[] screensToLoad)
        {
            this.loadingIsSlow = loadingIsSlow;
            this.screensToLoad = screensToLoad ?? throw new ArgumentNullException(nameof(screensToLoad));

            loadingText = new Text(Resources.LoadingScreenText);

            TransitionOnTime = TimeSpan.FromSeconds(DefaultTransitionOnTime);
        }

        /// <summary>
        /// Loads the specified screens, replacing all current screens.
        /// </summary>
        /// <param name="screenManager">The screen manager.</param>
        /// <param name="isLoadingSlow">Whether loading is slow and should show a message.</param>
        /// <param name="controllingPlayer">The controlling player.</param>
        /// <param name="screensToLoad">The screens to load.</param>
        public static void Load(ScreenManager screenManager, bool isLoadingSlow, PlayerIndex? controllingPlayer, params GameScreen[] screensToLoad)
        {
            if (screenManager == null)
                throw new ArgumentNullException(nameof(screenManager));

            foreach (GameScreen screen in screenManager.GetScreens())
            {
                screen.ExitScreen();
            }

            LoadingScreen loadingScreen = new LoadingScreen(isLoadingSlow, screensToLoad);
            screenManager.AddScreen(loadingScreen, controllingPlayer);
        }

        /// <summary>
        /// Updates the loading screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="otherScreenHasFocus">Whether another screen has focus.</param>
        /// <param name="coveredByOtherScreen">Whether this screen is covered by another screen.</param>
        public override void Update(GameTime gameTime, bool otherScreenHasFocus, bool coveredByOtherScreen)
        {
            base.Update(gameTime, otherScreenHasFocus, coveredByOtherScreen);

            if (otherScreensAreGone)
            {
                ScreenManager.RemoveScreen(this);

                foreach (GameScreen screen in screensToLoad)
                {
                    if (screen != null)
                    {
                        ScreenManager.AddScreen(screen, ControllingPlayer);
                    }
                }

                ScreenManager.Game.ResetElapsedTime();
            }
        }

        /// <summary>
        /// Draws the loading screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(GameTime gameTime)
        {
            if (ScreenState == ScreenState.Active &&
                ScreenManager.GetScreens().Length == SingleScreenCount)
            {
                otherScreensAreGone = true;
            }

            if (loadingIsSlow)
            {
                SpriteBatch spriteBatch = ScreenManager.SpriteBatch;
                SpriteFont font = ScreenManager.Font;
                Vector2 textSize = font.MeasureString(Resources.LoadingScreenText);

                spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, ScreenManager.GlobalTransformation);

                loadingText.SpriteFont = font;
                loadingText.Position = (ScreenManager.BaseScreenSize - textSize) / 2;
                loadingText.Color = Color.White * TransitionAlpha;
                loadingText.Scale = Vector2.One;
                loadingText.Origin = Vector2.Zero;
                loadingText.Draw(spriteBatch);

                spriteBatch.End();
            }
        }
    }
}
