using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input.Touch;
using Snake.Core.Common;
using Snake.Core.Enums;
using Snake.Core.Events;
using Snake.Core.Graphics;
using Snake.Core.Inputs;
using Snake.Core.Models;
using System;
using System.Collections.Generic;

namespace Snake.Core.Screens
{
    /// <summary>
    /// Base class for screens that display a menu.
    /// </summary>
    public abstract class MenuScreen : GameScreen
    {
        /// <summary>
        /// The menu entries.
        /// </summary>
        private readonly List<MenuEntry> menuEntries = new List<MenuEntry>();

        /// <summary>
        /// The selected entry.
        /// </summary>
        protected int selectedEntry;

        /// <summary>
        /// The menu title.
        /// </summary>
        private string menuTitle;

        /// <summary>
        /// The menu title text.
        /// </summary>
        private readonly Text menuTitleText;

        /// <summary>
        /// Gets or sets the menu title.
        /// </summary>
        public string Title
        {
            get => menuTitle;
            set => menuTitle = value;
        }

        /// <summary>
        /// Gets the menu entries.
        /// </summary>
        protected IList<MenuEntry> MenuEntries => menuEntries;

        /// <summary>
        /// Initializes a new instance of the MenuScreen class.
        /// </summary>
        /// <param name="menuTitle">The menu title.</param>
        public MenuScreen(string menuTitle)
        {
            ArgumentNullException.ThrowIfNull(menuTitle);

            this.menuTitle = menuTitle;
            menuTitleText = new Text(menuTitle);

            TransitionOnTime = TimeSpan.FromSeconds(DefaultTransitionTime);
            TransitionOffTime = TimeSpan.FromSeconds(DefaultTransitionTime);
        }

        /// <summary>
        /// Handles the input for the menu screen.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        /// <param name="inputState">The input state.</param>
        public override void HandleInput(GameTime gameTime, InputState inputState)
        {
            base.HandleInput(gameTime, inputState);

            // Check if the screen is on mobile
            if (SnakeGame.IsMobile)
            {
                var touchState = inputState.CurrentTouchState;
                if (touchState.Count > 0)
                {
                    foreach (var touch in touchState)
                    {
                        if (touch.State == TouchLocationState.Pressed)
                        {
                            TextSelectedCheck(inputState.CurrentCursorLocation);
                        }
                    }
                }
            }
            // Check if the screen is on desktop
            else if (SnakeGame.IsDesktop)
            {
                if (inputState.IsLeftMouseButtonClicked())
                {
                    TextSelectedCheck(inputState.CurrentCursorLocation);
                }
                else if (inputState.IsMiddleMouseButtonClicked())
                {
                    OnSelectEntry(selectedEntry, PlayerIndex.One);
                }
            }

            // Check if the menu is up
            if (inputState.IsMenuUp(ControllingPlayer))
            {
                selectedEntry--;

                if (selectedEntry < 0)
                    selectedEntry = menuEntries.Count - 1;

                SetPreviousEnabledMenu();
            }

            // Check if the menu is down
            if (inputState.IsMenuDown(ControllingPlayer))
            {
                selectedEntry++;

                if (selectedEntry >= menuEntries.Count)
                    selectedEntry = 0;

                SetNextEnabledMenu();
            }


            // Check if the menu is selected
            PlayerIndex playerIndex;
            if (inputState.IsMenuSelect(ControllingPlayer, out playerIndex))
            {
                OnSelectEntry(selectedEntry, playerIndex);
            }
            // Check if the menu is cancelled
            else if (inputState.IsMenuCancel(ControllingPlayer, out playerIndex))
            {
                OnCancel(playerIndex);
            }
        }

        /// <summary>
        /// Checks if a touch location intersects with any menu entry.
        /// </summary>
        /// <param name="touchLocation">The touch location.</param>
        private void TextSelectedCheck(Vector2 touchLocation)
        {
            for (int i = 0; i < menuEntries.Count; i++)
            {
                MenuEntry entry = menuEntries[i];
                Rectangle entryBounds = entry.MenuEntryText.RectangleBounds;

                // Check if the touch location intersects with the menu entry
                if (entryBounds.Contains(touchLocation))
                {
                    selectedEntry = i;
                    OnSelectEntry(selectedEntry, ControllingPlayer ?? PlayerIndex.One);
                    break;
                }
            }
        }

        /// <summary>
        /// Sets the next enabled menu entry.
        /// </summary>
        private void SetNextEnabledMenu()
        {
            if (menuEntries.Count == 0) return;

            int startIndex = selectedEntry;
            int iterations = 0;

            while (!menuEntries[selectedEntry].Enabled && iterations < menuEntries.Count)
            {
                selectedEntry++;

                if (selectedEntry >= menuEntries.Count)
                    selectedEntry = 0;

                iterations++;

                if (selectedEntry == startIndex && iterations > 0)
                    break;
            }
        }

        /// <summary>
        /// Sets the previous enabled menu entry.
        /// </summary>
        private void SetPreviousEnabledMenu()
        {
            if (menuEntries.Count == 0) return;

            int startIndex = selectedEntry;
            int iterations = 0;

            while (!menuEntries[selectedEntry].Enabled && iterations < menuEntries.Count)
            {
                selectedEntry--;

                if (selectedEntry < 0)
                    selectedEntry = menuEntries.Count - 1;

                iterations++;

                if (selectedEntry == startIndex && iterations > 0)
                    break;
            }
        }

        /// <summary>
        /// Invokes the Selected event for the selected entry.
        /// </summary>
        /// <param name="entryIndex">The index of the entry.</param>
        /// <param name="playerIndex">The player index that selected the entry.</param>
        protected virtual void OnSelectEntry(int entryIndex, PlayerIndex playerIndex)
        {
            menuEntries[entryIndex].OnSelectEntry(playerIndex);
        }

        /// <summary>
        /// Exits the screen.
        /// </summary>
        /// <param name="playerIndex">The player index that cancelled the entry.</param>
        protected virtual void OnCancel(PlayerIndex playerIndex)
        {
            ExitScreen();
        }

        /// <summary>
        /// Invokes the Cancel event.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        protected void OnCancel(object sender, PlayerIndexEventArgs e)
        {
            OnCancel(e.PlayerIndex);
        }

        /// <summary>
        /// Updates the menu entry locations.
        /// </summary>
        /// <param name="titlePosition">The title position.</param>
        protected virtual void UpdateMenuEntryLocations(Vector2 titlePosition)
        {
            float transitionOffset = (float)Math.Pow(TransitionPosition, 2);
            Vector2 position = Helper.GetCenterScreenVector2(ScreenManager.BaseScreenSize);
            position.Y += titlePosition.Y / 2.0f;

            // Update the menu entry locations
            for (int i = 0; i < menuEntries.Count; i++)
            {
                MenuEntry menuEntry = menuEntries[i];

                // Calculate the position of the menu entry
                position.X = ScreenManager.BaseScreenSize.X / 2 - menuEntry.GetWidth(this) / 2;

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

        public override void Update(GameTime gameTime, bool otherScreenHasFocus, bool coveredByOtherScreen)
        {
            base.Update(gameTime, otherScreenHasFocus, coveredByOtherScreen);

            // Check if the selected entry is enabled
            if (menuEntries.Count > 0 && selectedEntry < menuEntries.Count)
            {
                if (!menuEntries[selectedEntry].Enabled)
                {
                    SetNextEnabledMenu();
                }
            }

            // Update the menu entries
            for (int i = 0; i < menuEntries.Count; i++)
            {
                bool isSelected = IsActive && (i == selectedEntry);

                menuEntries[i].Update(this, isSelected, gameTime);
            }
        }

        public override void Draw(GameTime gameTime)
        {
            SpriteBatch spriteBatch = ScreenManager.SpriteBatch;
            SpriteFont font = ScreenManager.Font;

            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, ScreenManager.GlobalTransformation);

            // Draw the menu entries
            for (int i = 0; i < menuEntries.Count; i++)
            {
                MenuEntry menuEntry = menuEntries[i];

                bool isSelected = IsActive && (i == selectedEntry);

                menuEntry.Draw(this, isSelected, gameTime);
            }

            // Title text
            menuTitleText.SpriteFont = font;
            menuTitleText.Scale = new Vector2(TitleScale, TitleScale);
            menuTitleText.Color = Color.White * TransitionAlpha;

            // Calculate the position of the title text
            float transitionOffset = (float)Math.Pow(TransitionPosition, 2);
            Vector2 position = Helper.GetCenterScreenVector2(ScreenManager.GraphicsDevice.Viewport, menuTitleText.GetTextSize());
            position.Y = TitlePositionYOffset - transitionOffset * TransitionOffsetMultiplier;

            // Set the position of the title text and draw it
            menuTitleText.Position = position;
            menuTitleText.Draw(spriteBatch);

            spriteBatch.End();

            UpdateMenuEntryLocations(position);
        }
    }
}
