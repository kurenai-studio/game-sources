using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Common;
using Snake.Core.Events;
using Snake.Core.Graphics;
using Snake.Core.Localization;
using Snake.Core.Managers;
using Snake.Core.Models;
using Snake.Core.Settings;
using System;
using System.ComponentModel;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays game settings.
    /// </summary>
    public class SettingsScreen : MenuScreen
    {
        /// <summary>
        /// The music menu entry.
        /// </summary>
        private readonly MenuEntry musicMenuEntry;

        /// <summary>
        /// The sound effects menu entry.
        /// </summary>
        private readonly MenuEntry soundEffectsMenuEntry;

        /// <summary>
        /// The back menu entry.
        /// </summary>
        private readonly MenuEntry backMenuEntry;

        /// <summary>
        /// The settings manager.
        /// </summary>
        private SettingsManager<GameSettings> settingsManager;

        /// <summary>
        /// Initializes a new instance of the SettingsScreen class.
        /// </summary>
        public SettingsScreen() : base(Resources.SettingsScreenTitle)
        {
            musicMenuEntry = new MenuEntry($"{Resources.MusicMenuText} {Resources.MusicOnMenuText}");
            soundEffectsMenuEntry = new MenuEntry($"{Resources.SoundEffectsMenuText} {Resources.SoundEffectsOnMenuText}");
            backMenuEntry = new MenuEntry(Resources.BackMenuText);

            musicMenuEntry.Selected += MusicMenuEntrySelected;
            soundEffectsMenuEntry.Selected += SoundEffectsMenuEntrySelected;
            backMenuEntry.Selected += OnCancel;

            MenuEntries.Add(musicMenuEntry);
            MenuEntries.Add(soundEffectsMenuEntry);
            MenuEntries.Add(backMenuEntry);
        }

        /// <summary>
        /// Loads the settings screen content.
        /// </summary>
        public override void LoadContent()
        {
            base.LoadContent();

            settingsManager ??= ScreenManager.Game.Services.GetService<SettingsManager<GameSettings>>();

            if (settingsManager != null)
            {
                settingsManager.Settings.PropertyChanged += OnSettingsPropertyChanged;
                SetMenuTexts();
            }
        }

        /// <summary>
        /// Handles settings property changes.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void OnSettingsPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            SetMenuTexts();
            settingsManager?.Save();
        }

        /// <summary>
        /// Updates the settings screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="otherScreenHasFocus">Whether another screen has focus.</param>
        /// <param name="coveredByOtherScreen">Whether this screen is covered by another screen.</param>
        public override void Update(GameTime gameTime, bool otherScreenHasFocus, bool coveredByOtherScreen)
        {
            base.Update(gameTime, otherScreenHasFocus, coveredByOtherScreen);

            if (settingsManager != null && string.IsNullOrEmpty(musicMenuEntry.Text))
            {
                SetMenuTexts();
            }
        }

        /// <summary>
        /// Sets the menu entry texts based on current settings.
        /// </summary>
        private void SetMenuTexts()
        {
            if (settingsManager == null) return;

            string musicMessage = settingsManager.Settings.MusicEnabled
                ? Resources.MusicOnMenuText
                : Resources.MusicOffMenuText;
            musicMenuEntry.Text = $"{Resources.MusicMenuText} {musicMessage}";

            string soundEffectsMessage = settingsManager.Settings.SoundEffectsEnabled
                ? Resources.SoundEffectsOnMenuText
                : Resources.SoundEffectsOffMenuText;
            soundEffectsMenuEntry.Text = $"{Resources.SoundEffectsMenuText} {soundEffectsMessage}";

            backMenuEntry.Text = Resources.BackMenuText;
        }

        /// <summary>
        /// Handles the music menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void MusicMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            if (settingsManager == null) return;

            settingsManager.Settings.MusicEnabled = !settingsManager.Settings.MusicEnabled;
            SetMenuTexts();
        }

        /// <summary>
        /// Handles the sound effects menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void SoundEffectsMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            if (settingsManager == null) return;

            settingsManager.Settings.SoundEffectsEnabled = !settingsManager.Settings.SoundEffectsEnabled;
            SetMenuTexts();
        }

        /// <summary>
        /// Draws the settings screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(GameTime gameTime)
        {
            ScreenManager.FadeBackBufferToBlack(TransitionAlpha * FadeAlphaMultiplier);

            SpriteBatch spriteBatch = ScreenManager.SpriteBatch;
            SpriteFont font = ScreenManager.Font;

            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, ScreenManager.GlobalTransformation);

            for (int i = 0; i < MenuEntries.Count; i++)
            {
                MenuEntry menuEntry = MenuEntries[i];
                bool isSelected = IsActive && (i == selectedEntry);
                menuEntry.Draw(this, isSelected, gameTime);
            }

            float transitionOffset = (float)Math.Pow(TransitionPosition, 2);
            Vector2 textSize = font.MeasureString(Title);
            Color color = Color.White * TransitionAlpha;
            Vector2 scale = new Vector2(TitleScale, TitleScale);
            Vector2 scaledTextSize = textSize * scale;
            Vector2 position = Helper.GetCenterScreenVector2(ScreenManager.GraphicsDevice.Viewport, scaledTextSize);
            position.Y = TitlePositionYOffset - transitionOffset * TransitionOffsetMultiplier;

            Text titleText = new Text(Title);
            titleText.SpriteFont = font;
            titleText.Position = position;
            titleText.Color = color;
            titleText.Scale = scale;
            titleText.Draw(spriteBatch);

            spriteBatch.End();

            UpdateMenuEntryLocations(position);
        }
    }
}
