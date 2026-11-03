using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Managers;
using Snake.Core.Screens;
using System;

namespace Snake.Core.Models
{
    /// <summary>
    /// A menu entry specifically for leaderboard scores that can display in gold for top 3.
    /// </summary>
    public class LeaderboardMenuEntry : MenuEntry
    {
        /// <summary>
        /// Whether this entry should be displayed in gold (for top 3).
        /// </summary>
        private readonly bool isTopThree;

        /// <summary>
        /// Initializes a new instance of the LeaderboardMenuEntry class.
        /// </summary>
        /// <param name="text">The text to display.</param>
        /// <param name="enabled">Whether the entry is enabled.</param>
        /// <param name="isTopThree">Whether this is a top 3 entry (will be displayed in gold).</param>
        public LeaderboardMenuEntry(string text, bool enabled, bool isTopThree) : base(text, enabled)
        {
            this.isTopThree = isTopThree;
            Enabled = enabled;
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
            else if (isTopThree)
            {
                // Top 3 entries are always gold (not affected by selection)
                color = Color.Gold;
            }
            else
            {
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

        /// <summary>
        /// Gets the height of the menu entry (reduced padding for tighter spacing).
        /// </summary>
        /// <param name="screen">The menu screen containing this entry.</param>
        /// <returns>The height in pixels.</returns>
        public override int GetHeight(MenuScreen screen)
        {
            // Return reduced height for tighter spacing between leaderboard entries
            return screen.ScreenManager.Font.LineSpacing + 10; // Reduced from default 30 padding to 10
        }
    }
}

