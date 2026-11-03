using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Common;
using Snake.Core.Enums;
using Snake.Core.Events;
using Snake.Core.Localization;
using Snake.Core.Models;
using System;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays information about the game's assets and acknowledgements.
    /// </summary>
    public class AboutScreen : MenuScreen
    {
        /// <summary>
        /// Thank you menu entry (disabled, informational).
        /// </summary>
        private readonly AboutMenuEntry thankYouMenuEntry;

        /// <summary>
        /// Snake sprites pack menu entry.
        /// </summary>
        private readonly AboutMenuEntry snakeSpritesPackMenuEntry;

        /// <summary>
        /// Background pixel pack menu entry.
        /// </summary>
        private readonly AboutMenuEntry backgroundPixelPackMenuEntry;

        /// <summary>
        /// Background music menu entry.
        /// </summary>
        private readonly AboutMenuEntry backgroundMusicMenuEntry;

        /// <summary>
        /// Brackeys sound effects menu entry.
        /// </summary>
        private readonly AboutMenuEntry brackeysSoundEffectsMenuEntry;

        /// <summary>
        /// Built with MonoGame menu entry.
        /// </summary>
        private readonly AboutMenuEntry builtWithMonoGameMenuEntry;

        /// <summary>
        /// Back menu entry.
        /// </summary>
        private readonly AboutMenuEntry backMenuEntry;

        /// <summary>
        /// Initializes a new instance of the AboutScreen class.
        /// </summary>
        public AboutScreen() : base(Resources.AboutScreenTitle)
        {
            // Create menu entries with URLs
            snakeSpritesPackMenuEntry = new AboutMenuEntry(
                Resources.SnakeSpritesPackMenuText, 
                true, 
                "https://cosme.itch.io/snake"
            );
            snakeSpritesPackMenuEntry.Selected += OnLinkSelected;

            backgroundPixelPackMenuEntry = new AboutMenuEntry(
                Resources.BackgroundPixelPackMenuText, 
                true, 
                "https://blue00.itch.io/backgrounds-pixel-pack"
            );
            backgroundPixelPackMenuEntry.Selected += OnLinkSelected;

            backgroundMusicMenuEntry = new AboutMenuEntry(
                Resources.BackgroundMusicMenuText, 
                true, 
                "https://mass-kamm.itch.io/free-bgm"
            );
            backgroundMusicMenuEntry.Selected += OnLinkSelected;

            brackeysSoundEffectsMenuEntry = new AboutMenuEntry(
                Resources.BrackeysSoundEffectsMenuText, 
                true, 
                "https://brackeysgames.itch.io/brackeys-platformer-bundle"
            );
            brackeysSoundEffectsMenuEntry.Selected += OnLinkSelected;

            builtWithMonoGameMenuEntry = new AboutMenuEntry(
                Resources.BuiltWithMonoGame, 
                true, 
                "https://www.monogame.net/"
            );
            builtWithMonoGameMenuEntry.Selected += OnLinkSelected;

            // Thank you text (disabled, informational)
            thankYouMenuEntry = new AboutMenuEntry(Resources.ThankyouMenuText, false);

            // Back menu entry
            backMenuEntry = new AboutMenuEntry(Resources.BackMenuText);
            backMenuEntry.Selected += OnCancel;

            // Add menu entries in order
            MenuEntries.Add(snakeSpritesPackMenuEntry);
            MenuEntries.Add(backgroundPixelPackMenuEntry);
            MenuEntries.Add(backgroundMusicMenuEntry);
            MenuEntries.Add(brackeysSoundEffectsMenuEntry);
            MenuEntries.Add(builtWithMonoGameMenuEntry);
            MenuEntries.Add(thankYouMenuEntry);
            MenuEntries.Add(backMenuEntry);

            TransitionOnTime = TimeSpan.FromSeconds(DefaultTransitionTime);
            TransitionOffTime = TimeSpan.FromSeconds(DefaultTransitionTime);
        }

        /// <summary>
        /// Handles link selection to open URLs.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void OnLinkSelected(object sender, PlayerIndexEventArgs e)
        {
            if (sender is AboutMenuEntry entry && entry.HasUrl)
            {
                entry.OpenUrl();
            }
        }

        /// <summary>
        /// Updates the menu entry locations to properly center them.
        /// </summary>
        /// <param name="titlePosition">The title position.</param>
        protected override void UpdateMenuEntryLocations(Vector2 titlePosition)
        {
            float transitionOffset = (float)Math.Pow(TransitionPosition, 2);
            Vector2 position = Helper.GetCenterScreenVector2(ScreenManager.GraphicsDevice.Viewport, Vector2.Zero);
            // Start menu entries closer to the title (reduced spacing)
            position.Y = titlePosition.Y + (ScreenManager.Font.LineSpacing * TitleScale) + 40f;

            // Update the menu entry locations
            for (int i = 0; i < MenuEntries.Count; i++)
            {
                MenuEntry menuEntry = MenuEntries[i];

                // Get the actual scaled width of the text
                Vector2 textSize = ScreenManager.Font.MeasureString(menuEntry.Text);
                float scaledWidth = textSize.X * 1.2f; // BaseScale from MenuEntry

                // Calculate the position of the menu entry (centered using actual viewport width)
                position.X = ScreenManager.GraphicsDevice.Viewport.Width / 2f - scaledWidth / 2f;

                // Apply the transition offset
                if (ScreenState == ScreenState.TransitionOn)
                    position.X -= transitionOffset * TransitionXOffsetOn;
                else
                    position.X += transitionOffset * TransitionXOffsetOff;

                // Set the position of the menu entry
                menuEntry.Position = position;
                position.Y += menuEntry.GetHeight(this);
            }
        }

        /// <summary>
        /// Draws the settings screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(GameTime gameTime)
        {
            ScreenManager.FadeBackBufferToBlack(TransitionAlpha * FadeAlphaMultiplier);

            base.Draw(gameTime);
        }
    }
}
