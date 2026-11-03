using Microsoft.Xna.Framework;
using Snake.Core.Events;
using Snake.Core.Localization;
using Snake.Core.Models;
using System;

namespace Snake.Core.Screens
{
    /// <summary>
    /// The main menu screen of the game.
    /// </summary>
    public class MainMenuScreen : MenuScreen
    {
        /// <summary>
        /// The play menu entry.
        /// </summary>
        private readonly MenuEntry playMenuEntry;

        /// <summary>
        /// The leaderboard menu entry.
        /// </summary>
        private readonly MenuEntry leaderboardMenuEntry;

        /// <summary>
        /// The settings menu entry.
        /// </summary>
        private readonly MenuEntry settingsMenuEntry;

        /// <summary>
        /// The about menu entry.
        /// </summary>
        private readonly MenuEntry aboutMenuEntry;

        /// <summary>
        /// The exit menu entry.
        /// </summary>
        private readonly MenuEntry exitMenuEntry;

        /// <summary>
        /// Initializes a new instance of the MainMenuScreen class.
        /// </summary>
        public MainMenuScreen() : base(Resources.MainMenuScreenTitle)
        {
            // Initialize menu entries
            playMenuEntry = new MenuEntry(Resources.PlayMenuText);
            leaderboardMenuEntry = new MenuEntry(Resources.LeaderboardMenuText);
            aboutMenuEntry = new MenuEntry(Resources.AboutMenuText);
            settingsMenuEntry = new MenuEntry(Resources.SettingsMenuText);
            exitMenuEntry = new MenuEntry(Resources.ExitMenuText);

            // Add event handlers to menu entries
            playMenuEntry.Selected += PlayMenuEntrySelected;
            leaderboardMenuEntry.Selected += LeaderboardMenuEntry_Selected;
            aboutMenuEntry.Selected += AboutMenuEntrySelected;
            settingsMenuEntry.Selected += SettingsMenuEntrySelected;
            exitMenuEntry.Selected += OnCancel;

            // Add menu entries to the menu
            MenuEntries.Add(playMenuEntry);
            MenuEntries.Add(leaderboardMenuEntry);
            MenuEntries.Add(aboutMenuEntry);
            MenuEntries.Add(settingsMenuEntry);
            MenuEntries.Add(exitMenuEntry);
        }

        /// <summary>
        /// Sets the menu entry texts and title.
        /// </summary>
        private void SetMenuTexts()
        {
            playMenuEntry.Text = Resources.PlayMenuText;
            leaderboardMenuEntry.Text = Resources.LeaderboardMenuText;
            aboutMenuEntry.Text = Resources.AboutMenuText;
            settingsMenuEntry.Text = Resources.SettingsMenuText;
            exitMenuEntry.Text = Resources.ExitMenuText;

            // Set the title
            Title = Resources.GameTitle;
        }

        /// <summary>
        /// Loads the main menu content.
        /// </summary>
        public override void LoadContent()
        {
            base.LoadContent();

            // Set the menu texts
            SetMenuTexts();
        }

        /// <summary>
        /// Handles the play menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void PlayMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            // Add the gameplay screen to the screen manager
            ScreenManager.AddScreen(new GameplayScreen(), e.PlayerIndex);
        }

        /// <summary>
        /// Handles the leaderboard menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void LeaderboardMenuEntry_Selected(object sender, PlayerIndexEventArgs e)
        {
            // Add the leaderboard screen to the screen manager
            ScreenManager.AddScreen(new LeaderboardScreen(), e.PlayerIndex);
        }

        /// <summary>
        /// Handles the about menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void AboutMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            // Add the about screen to the screen manager
            ScreenManager.AddScreen(new AboutScreen(), e.PlayerIndex);
        }

        /// <summary>
        /// Handles the settings menu entry selection.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void SettingsMenuEntrySelected(object sender, PlayerIndexEventArgs e)
        {
            // Add the settings screen to the screen manager
            ScreenManager.AddScreen(new SettingsScreen(), e.PlayerIndex);
        }

        /// <summary>
        /// Handles the cancel action (exit).
        /// </summary>
        /// <param name="playerIndex">The player index.</param>
        protected override void OnCancel(PlayerIndex playerIndex)
        {
            // Show the confirm exit message box
            string message = Resources.ExitMenuQuestion;
            MessageBoxScreen confirmExitMessageBox = new MessageBoxScreen(message);
            confirmExitMessageBox.Accepted += ConfirmExitMessageBoxAccepted;

            ScreenManager.AddScreen(confirmExitMessageBox, playerIndex);
        }

        /// <summary>
        /// Handles the confirm exit message box acceptance.
        /// </summary>
        /// <param name="sender">The event sender.</param>
        /// <param name="e">The event arguments.</param>
        private void ConfirmExitMessageBoxAccepted(object sender, PlayerIndexEventArgs e)
        {
            // Exit the game
            ScreenManager.Game.Exit();
        }
    }
}
