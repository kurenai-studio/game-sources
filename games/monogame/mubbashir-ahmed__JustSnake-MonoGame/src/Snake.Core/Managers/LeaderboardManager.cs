using Snake.Core.Models;
using Snake.Core.Settings;
using Snake.Core.Storages.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Snake.Core.Managers
{
    /// <summary>
    /// Represents a leaderboard manager.
    /// </summary>
    /// <typeparam name="T">The type of the leaderboard.</typeparam>
    public class LeaderboardManager<T> where T : new()
    {
        /// <summary>
        /// The storage implementation used by this manager.
        /// </summary>
        private readonly ISettingsStorage storage;

        /// <summary>
        /// The current leaderboard instance.
        /// </summary>
        private T leaderboard;

        /// <summary>
        /// Occurs when leaderboard is loaded.
        /// </summary>
        public event Action<T> LeaderboardLoaded;

        /// <summary>
        /// Occurs when leaderboard is saved.
        /// </summary>
        public event Action<T> LeaderboardSaved;

        /// <summary>
        /// Gets the storage implementation used by this manager.
        /// </summary>
        public ISettingsStorage Storage => storage;

        /// <summary>
        /// Gets the current leaderboard instance.
        /// </summary>
        public T Leaderboard => leaderboard;

        /// <summary>
        /// Initializes a new instance of the LeaderboardManager class.
        /// </summary>
        /// <param name="storage">The storage implementation to use.</param>
        /// <exception cref="ArgumentNullException">Thrown when storage is null.</exception>
        public LeaderboardManager(ISettingsStorage storage)
        {
            ArgumentNullException.ThrowIfNull(storage);

            this.storage = storage;

            // Load the leaderboard
            Load();
        }

        /// <summary>
        /// Saves the current leaderboard to storage.
        /// </summary>
        public void Save()
        {
            // Try to load the leaderboard
            try
            {
                // Save the leaderboard
                storage.SaveLeaderboard(leaderboard);

                // Invoke the leaderboard saved event
                LeaderboardSaved?.Invoke(leaderboard);
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to save leaderboard: {ex}");
            }
        }

        /// <summary>
        /// Loads leaderboard from storage, or creates default leaderboard if loading fails.
        /// </summary>
        public void Load()
        {
            try
            {
                // Load the leaderboard
                leaderboard = storage.LoadLeaderboard<T>() ?? new T();
            }
            catch (Exception)
            {
                // If loading fails, initialize with default leaderboard
                leaderboard = new T();
            }

            // Invoke the leaderboard loaded event
            LeaderboardLoaded?.Invoke(leaderboard);
        }

        /// <summary>
        /// Adds a score to the leaderboard if it qualifies (better than 10th place).
        /// </summary>
        /// <param name="score">The score to add.</param>
        /// <returns>True if the score was added, false otherwise.</returns>
        public bool AddScore(int score)
        {
            // Check if leaderboard is of type Leaderboard (has LeaderboardEntries property)
            if (leaderboard is Leaderboard leaderboardData)
            {
                // Initialize entries if null
                if (leaderboardData.LeaderboardEntries == null)
                {
                    leaderboardData.LeaderboardEntries = new List<LeaderboardEntry>();
                }

                // Check if score qualifies (if we have less than 10 entries, or score is better than the 10th entry)
                bool qualifies = leaderboardData.LeaderboardEntries.Count < 10 || 
                                score > leaderboardData.LeaderboardEntries.Min(e => e.Score);

                if (qualifies)
                {
                    // Add the new entry
                    LeaderboardEntry newEntry = new LeaderboardEntry
                    {
                        Score = score,
                        Date = DateTime.Now
                    };

                    leaderboardData.LeaderboardEntries.Add(newEntry);

                    // Sort by score descending
                    leaderboardData.LeaderboardEntries = leaderboardData.LeaderboardEntries
                        .OrderByDescending(e => e.Score)
                        .ToList();

                    // Keep only top 10
                    if (leaderboardData.LeaderboardEntries.Count > 10)
                    {
                        leaderboardData.LeaderboardEntries = leaderboardData.LeaderboardEntries
                            .Take(10)
                            .ToList();
                    }

                    // Save the leaderboard
                    Save();

                    return true;
                }
            }

            return false;
        }
    }
}
