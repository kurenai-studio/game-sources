using Snake.Core.Models;
using System.Collections.Generic;
using System.ComponentModel;

namespace Snake.Core.Settings
{
    public class Leaderboard : INotifyPropertyChanged
    {
        public List<LeaderboardEntry> LeaderboardEntries { get; set; }

        /// <summary>
        /// Occurs when a property value changes.
        /// </summary>
        public event PropertyChangedEventHandler PropertyChanged;

        public Leaderboard() 
        {
            LeaderboardEntries = new List<LeaderboardEntry>();
        }
    }
}
