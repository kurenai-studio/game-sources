using Microsoft.Xna.Framework;
using Snake.Core.Localization;
using Snake.Core.Managers;
using Snake.Core.Models;
using Snake.Core.Settings;
using System;
using System.Linq;

namespace Snake.Core.Screens
{
    /// <summary>
    /// A screen that displays the top 10 leaderboard scores.
    /// </summary>
    public class LeaderboardScreen : MenuScreen
    {
        /// <summary>
        /// The leaderboard manager.
        /// </summary>
        private LeaderboardManager<Leaderboard> leaderboardManager;

        /// <summary>
        /// The back menu entry.
        /// </summary>
        private readonly MenuEntry backMenuEntry;

        /// <summary>
        /// The no scores menu entry.
        /// </summary>
        private readonly MenuEntry noScoresMenuEntry;

        /// <summary>
        /// Initializes a new instance of the LeaderboardScreen class.
        /// </summary>
        public LeaderboardScreen() : base(Resources.LeaderboardScreenTitle)
        {
            noScoresMenuEntry = new MenuEntry("No scores yet. Play the game to set a high score!", false);
            backMenuEntry = new MenuEntry(Resources.BackMenuText);
            backMenuEntry.Enabled = true;
            backMenuEntry.Selected += OnCancel;

            // Add back menu entry to the menu
            MenuEntries.Add(backMenuEntry);

            TransitionOnTime = TimeSpan.FromSeconds(0.2);
            TransitionOffTime = TimeSpan.FromSeconds(0.2);
        }

        /// <summary>
        /// Loads the leaderboard screen content.
        /// </summary>
        public override void LoadContent()
        {
            base.LoadContent();

            leaderboardManager = ScreenManager.Game.Services.GetService<LeaderboardManager<Leaderboard>>();
            UpdateScoreEntries();
        }

        /// <summary>
        /// Updates the score menu entries based on the current leaderboard.
        /// </summary>
        private void UpdateScoreEntries()
        {
            // Remove all existing score entries (keep back menu entry)
            MenuEntries.Clear();
            
            // Ensure back menu entry is always at the end
            MenuEntries.Add(backMenuEntry);

            if (leaderboardManager?.Leaderboard?.LeaderboardEntries == null || 
                leaderboardManager.Leaderboard.LeaderboardEntries.Count == 0)
            {
                // Show "no scores" message
                MenuEntries.Insert(0, noScoresMenuEntry);

                // Reset selected entry to the back button (last entry)
                selectedEntry = MenuEntries.Count - 1;
                
                return;
            }

            var entries = leaderboardManager.Leaderboard.LeaderboardEntries
                .OrderByDescending(e => e.Score)
                .Take(10)
                .ToList();

            // Add score entries (insert before back menu entry)
            for (int i = entries.Count - 1; i >= 0; i--)
            {
                var entry = entries[i];
                int rank = i + 1;
                string dateString = entry.Date.ToString("MMMM dd, yyyy");
                string entryText = $"{rank}. {entry.Score} - {dateString}";
                
                // Create a custom menu entry that preserves gold color for top 3
                LeaderboardMenuEntry scoreEntry = new LeaderboardMenuEntry(entryText, true, i < 3);
                
                MenuEntries.Insert(0, scoreEntry);
            }

            // Reset selected entry to the first score entry (index 0)
            selectedEntry = 0;
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
