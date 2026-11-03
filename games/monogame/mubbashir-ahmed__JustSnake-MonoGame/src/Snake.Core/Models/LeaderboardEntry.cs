using System;

namespace Snake.Core.Models
{
    /// <summary>
    /// Represents a leaderboard entry.
    /// </summary>
    public class LeaderboardEntry
    {
        /// <summary>
        /// The score of the leaderboard entry.
        /// </summary>
        public int Score { get; set; }

        /// <summary>
        /// The date of the leaderboard entry.
        /// </summary>
        public DateTime Date { get; set; }
    }
}
