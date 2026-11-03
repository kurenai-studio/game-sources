using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Common;
using Snake.Core.Events;
using Snake.Core.Graphics;
using Snake.Core.Localization;
using Snake.Core.Models;
using System;
using System.Collections.Generic;
using System.IO;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays a message with menu options.
    /// </summary>
    public class MessageBoxScreen : MenuScreen
    {
        /// <summary>
        /// The vertical padding.
        /// </summary>
        private const int VerticalPadding = 16;

        /// <summary>
        /// The menu entry height.
        /// </summary>
        private const int MenuEntryHeight = 50;

        /// <summary>
        /// The message.
        /// </summary>
        private readonly string message;

        /// <summary>
        /// The sub-message.
        /// </summary>
        private readonly string subtitle;

        /// <summary>
        /// The message box title.
        /// </summary>
        private readonly Text messageBoxTitleText;

        /// <summary>
        /// The sub-message box title.
        /// </summary>
        private readonly Text messageBoxSubtitleText;

        /// <summary>
        /// The yes menu entry.
        /// </summary>
        private readonly MenuEntry yesMenuEntry;

        /// <summary>
        /// The no menu entry.
        /// </summary>
        private readonly MenuEntry noMenuEntry;

        /// <summary>
        /// Occurs when the message box is accepted.
        /// </summary>
        public event EventHandler<PlayerIndexEventArgs> Accepted;

        /// <summary>
        /// Occurs when the message box is cancelled.
        /// </summary>
        public event EventHandler<PlayerIndexEventArgs> Cancelled;

        /// <summary>
        /// Initializes a new instance of the MessageBoxScreen class with default Yes/No options.
        /// </summary>
        /// <param name="message">The message to display.</param>
        public MessageBoxScreen(string message) : this(message, string.Empty, false) { }

        /// <summary>
        /// Initializes a new instance of the MessageBoxScreen class.
        /// </summary>
        /// <param name="message">The message to display.</param>
        /// <param name="customMenu">Whether to use custom menu entries.</param>
        /// <param name="customMenuEntries">The custom menu entries dictionary.</param>
        public MessageBoxScreen(string message, string subtitle, bool customMenu, Dictionary<string, EventHandler<PlayerIndexEventArgs>> customMenuEntries = null) : base(message)
        {
            ArgumentNullException.ThrowIfNull(message);

            this.message = message;
            this.subtitle = subtitle;
            messageBoxTitleText = new Text(message);
            if (!string.IsNullOrEmpty(subtitle))
                messageBoxSubtitleText = new Text(subtitle);

            if (customMenu && customMenuEntries != null)
            {
                foreach (var entry in customMenuEntries)
                {
                    MenuEntry menuEntry = new MenuEntry(entry.Key);
                    menuEntry.Selected += entry.Value;
                    MenuEntries.Add(menuEntry);
                }
            }
            else
            {
                this.yesMenuEntry = new MenuEntry(Resources.YesMenuText);
                this.noMenuEntry = new MenuEntry(Resources.NoMenuText);

                this.yesMenuEntry.Selected += YesMenuEntrySelected;
                this.noMenuEntry.Selected += NoMenuEntrySelected;

                MenuEntries.Add(this.yesMenuEntry);
                MenuEntries.Add(this.noMenuEntry);
            }

            IsPopup = true;

            TransitionOnTime = TimeSpan.FromSeconds(DefaultTransitionTime);
            TransitionOffTime = TimeSpan.FromSeconds(DefaultTransitionTime);
        }

        /// <summary>
        /// Handles the yes menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void YesMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            Accepted?.Invoke(this, e);
            ExitScreen();
        }

        /// <summary>
        /// Handles the no menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void NoMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            Cancelled?.Invoke(this, e);
            ExitScreen();
        }

        /// <summary>
        /// Handles the cancel action.
        /// </summary>
        /// <param name="playerIndex">The player index.</param>
        protected override void OnCancel(PlayerIndex playerIndex)
        {
            Cancelled?.Invoke(this, new PlayerIndexEventArgs(playerIndex));
            ExitScreen();
        }

        /// <summary>
        /// Draws the message box screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(GameTime gameTime)
        {
            ScreenManager.FadeBackBufferToBlack(TransitionAlpha * FadeAlphaMultiplier);

            SpriteBatch spriteBatch = ScreenManager.SpriteBatch;
            SpriteFont font = ScreenManager.Font;

            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, ScreenManager.GlobalTransformation);
            
            messageBoxTitleText.SpriteFont = font;
            messageBoxTitleText.Scale = new Vector2(TitleScale, TitleScale);

            float transitionOffset = (float)Math.Pow(TransitionPosition, 2);
            Color color = Color.White * TransitionAlpha;
            Vector2 textSize = messageBoxTitleText.GetTextSize();
            Vector2 messageTextPosition = Helper.GetCenterScreenVector2(ScreenManager.GraphicsDevice.Viewport, textSize);
            messageTextPosition.Y = TitlePositionYOffset - transitionOffset * TransitionOffsetMultiplier;

            float menuHeight = MenuEntries.Count > 0 ? MenuEntries.Count * MenuEntryHeight : 0;
            textSize.Y += menuHeight + VerticalPadding * 2;

            messageBoxTitleText.Position = messageTextPosition;
            messageBoxTitleText.Color = color;
            messageBoxTitleText.Draw(spriteBatch);

            Vector2 messageSubtitleTextPosition = Vector2.Zero;
            if (messageBoxSubtitleText != null)
            {
                messageBoxSubtitleText.SpriteFont = font;
                messageBoxSubtitleText.Scale = new Vector2(1.5f, 1.5f);

                Vector2 subtitleTextSize = messageBoxSubtitleText.GetTextSize();
                messageSubtitleTextPosition = Helper.GetCenterScreenVector2(ScreenManager.GraphicsDevice.Viewport, subtitleTextSize);
                messageSubtitleTextPosition.Y = (messageTextPosition.Y / 2) + TitlePositionYOffset - transitionOffset * TransitionOffsetMultiplier;
                Color subtitleColor = Color.Yellow * TransitionAlpha;

                messageBoxSubtitleText.Position = messageSubtitleTextPosition;
                messageBoxSubtitleText.Color = subtitleColor;
                messageBoxSubtitleText.Draw(spriteBatch);
            }

            spriteBatch.End();

            // Draw menu entries
            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, ScreenManager.GlobalTransformation);
            for (int i = 0; i < MenuEntries.Count; i++)
            {
                MenuEntry menuEntry = MenuEntries[i];
                bool isSelected = IsActive && (i == selectedEntry);
                menuEntry.Draw(this, isSelected, gameTime);
            }
            spriteBatch.End();

            // Update menu entry locations
            UpdateMenuEntryLocations(messageBoxSubtitleText != null ? messageSubtitleTextPosition : messageTextPosition);
        }
    }
}
