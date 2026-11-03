using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Managers;
using Snake.Core.Models;
using System;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A menu entry specifically for about screen links that can open URLs.
    /// </summary>
    internal class AboutMenuEntry : MenuEntry
    {
        /// <summary>
        /// The URL to open when this entry is selected (optional).
        /// </summary>
        private readonly string url;

        /// <summary>
        /// The color for link entries (cyan).
        /// </summary>
        private readonly Color linkColor;

        /// <summary>
        /// Initializes a new instance of the AboutMenuEntry class.
        /// </summary>
        /// <param name="text">The text to display.</param>
        /// <param name="enabled">Whether the entry is enabled.</param>
        /// <param name="url">The URL to open when selected (optional).</param>
        /// <param name="linkColor">The color for link entries (default: Cyan).</param>
        public AboutMenuEntry(string text, bool enabled = true, string url = null, Color? linkColor = null) 
            : base(text, enabled)
        {
            this.url = url;
            this.linkColor = linkColor ?? Color.Cyan;
            Enabled = enabled;
        }

        /// <summary>
        /// Gets the URL associated with this entry.
        /// </summary>
        public string Url => url;

        /// <summary>
        /// Gets whether this entry has a URL.
        /// </summary>
        public bool HasUrl => !string.IsNullOrEmpty(url);

        /// <summary>
        /// Opens the URL in the default browser if this entry has one.
        /// </summary>
        public void OpenUrl()
        {
            if (HasUrl)
            {
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url) 
                { 
                    UseShellExecute = true 
                });
            }
        }

        /// <summary>
        /// Draws the menu entry.
        /// </summary>
        /// <param name="screen">The menu screen containing this entry.</param>
        /// <param name="isSelected">Whether this entry is currently selected.</param>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(MenuScreen screen, bool isSelected, GameTime gameTime)
        {
            // Calculate the color of the menu entry
            Color color;
            if (!Enabled)
            {
                color = Color.Gray;
            }
            else if (HasUrl)
            {
                // Link entries: yellow when selected, cyan when not selected
                color = isSelected ? Color.Yellow : linkColor;
            }
            else
            {
                // Regular entries: yellow when selected, white when not selected
                color = isSelected ? Color.Yellow : Color.White;
            }

            // Get the screen manager and sprite batch
            ScreenManager screenManager = screen.ScreenManager;
            SpriteBatch spriteBatch = screenManager.SpriteBatch;
            SpriteFont font = screenManager.Font;

            // Calculate the pulsate and scale value (only for enabled entries)
            float scaleValue = 1.2f;
            if (Enabled && isSelected)
            {
                double time = gameTime.TotalGameTime.TotalSeconds;
                float pulsate = (float)Math.Sin(time * 6.0f) + 1;
                scaleValue = 1.2f + pulsate * 0.05f;
            }
            Vector2 scale = new Vector2(scaleValue, scaleValue);

            // Calculate the origin
            Vector2 origin = new Vector2(0, font.LineSpacing / 2);

            // Set the sprite font, position, color, scale, and origin of the menu entry text
            MenuEntryText.SpriteFont = font;
            MenuEntryText.Position = Position;
            MenuEntryText.Color = color * screen.TransitionAlpha;
            MenuEntryText.Scale = scale;
            MenuEntryText.Origin = origin;

            // Draw the menu entry text
            MenuEntryText.Draw(spriteBatch);
        }
    }
}

