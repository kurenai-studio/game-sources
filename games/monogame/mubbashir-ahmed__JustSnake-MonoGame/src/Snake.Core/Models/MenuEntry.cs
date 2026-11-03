using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Events;
using Snake.Core.Graphics;
using Snake.Core.Managers;
using Snake.Core.Screens;
using System;

namespace Snake.Core.Models
{
    /// <summary>
    /// Represents a clickable menu entry.
    /// </summary>
    public class MenuEntry
    {
        /// <summary>
        /// The fade speed multiplier.
        /// </summary>
        private const float FadeSpeedMultiplier = 4.0f;

        /// <summary>
        /// The pulsate frequency.
        /// </summary>
        private const float PulsateFrequency = 6.0f;

        /// <summary>
        /// The base scale.
        /// </summary>
        private const float BaseScale = 1.2f;

        /// <summary>
        /// The pulsate scale factor.
        /// </summary>
        private const float PulsateScaleFactor = 0.05f;

        /// <summary>
        /// The height padding.
        /// </summary>
        private const int HeightPadding = 30;

        /// <summary>
        /// The maximum fade.
        /// </summary>
        private const float MaxFade = 1.0f;

        /// <summary>
        /// The minimum fade.
        /// </summary>
        private const float MinFade = 0.0f;

        /// <summary>
        /// The text of the menu entry.
        /// </summary>
        private string text;

        /// <summary>
        /// The enabled state of the menu entry.
        /// </summary>
        private bool enabled;
        
        /// <summary>
        /// The selection fade.
        /// </summary>
        private float selectionFade;
        
        /// <summary>
        /// The text of the menu entry.
        /// </summary>
        private Text menuEntryText;

        /// <summary>
        /// Occurs when the menu entry is selected.
        /// </summary>
        public event EventHandler<PlayerIndexEventArgs> Selected;

        /// <summary>
        /// Gets or sets the text of the menu entry.
        /// </summary>
        public string Text
        {
            get => text;
            set 
            { 
                text = value;
                if (menuEntryText != null)
                {
                    menuEntryText.TextString = value;
                }
            }
        }

        /// <summary>
        /// Gets or sets the text of the menu entry.
        /// </summary>
        public Text MenuEntryText { get => menuEntryText; set => menuEntryText = value; }

        /// <summary>
        /// Gets or sets the position of the menu entry.
        /// </summary>
        public Vector2 Position { get; set; }

        /// <summary>
        /// Gets or sets whether the menu entry is enabled.
        /// </summary>
        public bool Enabled { get; set; }

        /// <summary>
        /// Initializes a new instance of the MenuEntry class.
        /// </summary>
        /// <param name="text">The text to display.</param>
        /// <param name="enabled">Whether the entry is enabled.</param>
        public MenuEntry(string text, bool enabled = true)
        {
            this.text = text;
            this.enabled = enabled;
            menuEntryText = new Text(text);
        }

        /// <summary>
        /// Invokes the Selected event.
        /// </summary>
        /// <param name="playerIndex">The player index that selected the entry.</param>
        protected internal virtual void OnSelectEntry(PlayerIndex playerIndex)
        {
            Selected?.Invoke(this, new PlayerIndexEventArgs(playerIndex));
        }

        /// <summary>
        /// Updates the menu entry's selection fade.
        /// </summary>
        /// <param name="screen">The menu screen containing this entry.</param>
        /// <param name="isSelected">Whether this entry is currently selected.</param>
        /// <param name="gameTime">The game time.</param>
        public virtual void Update(MenuScreen screen, bool isSelected, GameTime gameTime)
        {
            float fadeSpeed = (float)gameTime.ElapsedGameTime.TotalSeconds * FadeSpeedMultiplier;

            // Check if the menu entry is selected and update the selection fade
            if (isSelected)
                selectionFade = Math.Min(selectionFade + fadeSpeed, MaxFade);
            else
                selectionFade = Math.Max(selectionFade - fadeSpeed, MinFade);
        }

        /// <summary>
        /// Draws the menu entry.
        /// </summary>
        /// <param name="screen">The menu screen containing this entry.</param>
        /// <param name="isSelected">Whether this entry is currently selected.</param>
        /// <param name="gameTime">The game time.</param>
        public virtual void Draw(MenuScreen screen, bool isSelected, GameTime gameTime)
        {
            // Calculate the color of the menu entry
            Color color = enabled
                ? (isSelected ? Color.Yellow : Color.White)
                : Color.Gray;

            // Get the screen manager and sprite batch
            ScreenManager screenManager = screen.ScreenManager;
            SpriteBatch spriteBatch = screenManager.SpriteBatch;
            SpriteFont font = screenManager.Font;

            // Calculate the pulsate and scale value
            double time = gameTime.TotalGameTime.TotalSeconds;
            float pulsate = (float)Math.Sin(time * PulsateFrequency) + 1;
            float scaleValue = BaseScale + pulsate * PulsateScaleFactor * selectionFade;
            Vector2 scale = new Vector2(scaleValue, scaleValue);

            // Calculate the origin
            Vector2 origin = new Vector2(0, font.LineSpacing / 2);

            // Set the sprite font, position, color, scale, and origin of the menu entry text
            menuEntryText.SpriteFont = font;
            menuEntryText.Position = Position;
            menuEntryText.Color = color * screen.TransitionAlpha;
            menuEntryText.Scale = scale;
            menuEntryText.Origin = origin;

            // Draw the menu entry text
            menuEntryText.Draw(spriteBatch);
        }

        /// <summary>
        /// Gets the height of the menu entry.
        /// </summary>
        /// <param name="screen">The menu screen containing this entry.</param>
        /// <returns>The height in pixels.</returns>
        public virtual int GetHeight(MenuScreen screen)
        {
            // Return the height of the menu entry
            return screen.ScreenManager.Font.LineSpacing + HeightPadding;
        }

        /// <summary>
        /// Gets the width of the menu entry.
        /// </summary>
        /// <param name="screen">The menu screen containing this entry.</param>
        /// <returns>The width in pixels.</returns>
        public virtual int GetWidth(MenuScreen screen)
        {
            // Return the width of the menu entry
            return (int)screen.ScreenManager.Font.MeasureString(text).X;
        }
    }
}
