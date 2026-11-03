using System;
using System.Collections.Generic;

namespace DungeonExplorer.Data
{
    /// <summary>
    /// Tracks player progress, achievements, and statistics across multiple games
    /// </summary>
    public class PlayerProgress
    {
        // Overall Statistics
        public int TotalGamesPlayed { get; set; }
        public int TotalScore { get; set; }
        public int HighestScore { get; set; }
        public int TotalTreasuresCollected { get; set; }
        public int TotalEnemiesDefeated { get; set; }
        public int HighestLevelReached { get; set; }
        public TimeSpan TotalPlayTime { get; set; }
        public TimeSpan BestCompletionTime { get; set; }

        // Achievements
        public Dictionary<string, bool> Achievements { get; set; }
        public Dictionary<string, DateTime> AchievementDates { get; set; }

        // Per-level statistics
        public Dictionary<int, LevelStats> LevelStatistics { get; set; }

        // Preferences and unlocks
        public PlayerPreferences Preferences { get; set; }
        public List<string> UnlockedContent { get; set; }

        public PlayerProgress()
        {
            Achievements = new Dictionary<string, bool>();
            AchievementDates = new Dictionary<string, DateTime>();
            LevelStatistics = new Dictionary<int, LevelStats>();
            Preferences = new PlayerPreferences();
            UnlockedContent = new List<string>();
            
            InitializeAchievements();
        }

        /// <summary>
        /// Initialize available achievements
        /// </summary>
        private void InitializeAchievements()
        {
            var achievementList = new[]
            {
                "first_treasure",      // Collect your first treasure
                "treasure_hunter",     // Collect 50 treasures
                "treasure_master",     // Collect 100 treasures
                "first_enemy",         // Defeat your first enemy
                "enemy_slayer",        // Defeat 100 enemies
                "enemy_destroyer",     // Defeat 500 enemies
                "survivor",            // Complete a level without taking damage
                "speed_runner",        // Complete a level in under 2 minutes
                "explorer",            // Complete 10 levels
                "dungeon_master",      // Complete 50 levels
                "high_scorer",         // Reach 10,000 points
                "score_master",        // Reach 100,000 points
                "marathon_runner",     // Play for 5 hours total
                "dedication",          // Play for 20 hours total
                "perfect_run"          // Complete a game without dying
            };

            foreach (var achievement in achievementList)
            {
                Achievements[achievement] = false;
            }
        }

        /// <summary>
        /// Update progress after completing a game
        /// </summary>
        public void UpdateGameProgress(int score, int level, int treasuresCollected, int enemiesDefeated, TimeSpan gameTime, bool died)
        {
            TotalGamesPlayed++;
            TotalScore += score;
            TotalTreasuresCollected += treasuresCollected;
            TotalEnemiesDefeated += enemiesDefeated;
            TotalPlayTime = TotalPlayTime.Add(gameTime);

            if (score > HighestScore)
                HighestScore = score;

            if (level > HighestLevelReached)
                HighestLevelReached = level;

            if (!died && (BestCompletionTime == TimeSpan.Zero || gameTime < BestCompletionTime))
                BestCompletionTime = gameTime;

            // Update level statistics
            if (!LevelStatistics.ContainsKey(level))
                LevelStatistics[level] = new LevelStats();
            
            LevelStatistics[level].UpdateStats(score, gameTime, !died);

            // Check for achievements
            CheckAchievements(treasuresCollected, enemiesDefeated, !died, gameTime);
        }

        /// <summary>
        /// Check and unlock achievements based on current progress
        /// </summary>
        private void CheckAchievements(int sessionTreasures, int sessionEnemies, bool survived, TimeSpan sessionTime)
        {
            // Treasure achievements
            if (sessionTreasures > 0)
                UnlockAchievement("first_treasure");
            if (TotalTreasuresCollected >= 50)
                UnlockAchievement("treasure_hunter");
            if (TotalTreasuresCollected >= 100)
                UnlockAchievement("treasure_master");

            // Enemy achievements
            if (sessionEnemies > 0)
                UnlockAchievement("first_enemy");
            if (TotalEnemiesDefeated >= 100)
                UnlockAchievement("enemy_slayer");
            if (TotalEnemiesDefeated >= 500)
                UnlockAchievement("enemy_destroyer");

            // Gameplay achievements
            if (survived)
                UnlockAchievement("survivor");
            if (sessionTime.TotalMinutes < 2)
                UnlockAchievement("speed_runner");

            // Progress achievements
            if (HighestLevelReached >= 10)
                UnlockAchievement("explorer");
            if (HighestLevelReached >= 50)
                UnlockAchievement("dungeon_master");

            // Score achievements
            if (HighestScore >= 10000)
                UnlockAchievement("high_scorer");
            if (HighestScore >= 100000)
                UnlockAchievement("score_master");

            // Time achievements
            if (TotalPlayTime.TotalHours >= 5)
                UnlockAchievement("marathon_runner");
            if (TotalPlayTime.TotalHours >= 20)
                UnlockAchievement("dedication");

            // Perfect run (would need additional tracking)
            // UnlockAchievement("perfect_run");
        }

        /// <summary>
        /// Unlock an achievement if not already unlocked
        /// </summary>
        public bool UnlockAchievement(string achievementId)
        {
            if (Achievements.ContainsKey(achievementId) && !Achievements[achievementId])
            {
                Achievements[achievementId] = true;
                AchievementDates[achievementId] = DateTime.Now;
                return true; // Achievement was just unlocked
            }
            return false; // Already unlocked or doesn't exist
        }

        /// <summary>
        /// Check if an achievement is unlocked
        /// </summary>
        public bool IsAchievementUnlocked(string achievementId)
        {
            return Achievements.ContainsKey(achievementId) && Achievements[achievementId];
        }

        /// <summary>
        /// Get all unlocked achievements
        /// </summary>
        public List<string> GetUnlockedAchievements()
        {
            var unlocked = new List<string>();
            foreach (var kvp in Achievements)
            {
                if (kvp.Value)
                    unlocked.Add(kvp.Key);
            }
            return unlocked;
        }

        /// <summary>
        /// Get completion percentage (achievements unlocked / total achievements)
        /// </summary>
        public float GetCompletionPercentage()
        {
            if (Achievements.Count == 0) return 0f;
            int unlocked = GetUnlockedAchievements().Count;
            return (float)unlocked / Achievements.Count * 100f;
        }

        /// <summary>
        /// Reset all progress (for new player or reset option)
        /// </summary>
        public void ResetProgress()
        {
            TotalGamesPlayed = 0;
            TotalScore = 0;
            HighestScore = 0;
            TotalTreasuresCollected = 0;
            TotalEnemiesDefeated = 0;
            HighestLevelReached = 0;
            TotalPlayTime = TimeSpan.Zero;
            BestCompletionTime = TimeSpan.Zero;

            LevelStatistics.Clear();
            UnlockedContent.Clear();
            
            InitializeAchievements(); // Reset achievements
            AchievementDates.Clear();
        }
    }

    /// <summary>
    /// Statistics for individual levels
    /// </summary>
    public class LevelStats
    {
        public int TimesPlayed { get; set; }
        public int TimesCompleted { get; set; }
        public int BestScore { get; set; }
        public TimeSpan BestTime { get; set; }
        public float CompletionRate => TimesPlayed > 0 ? (float)TimesCompleted / TimesPlayed : 0f;

        public void UpdateStats(int score, TimeSpan time, bool completed)
        {
            TimesPlayed++;
            
            if (completed)
            {
                TimesCompleted++;
                
                if (score > BestScore)
                    BestScore = score;
                    
                if (BestTime == TimeSpan.Zero || time < BestTime)
                    BestTime = time;
            }
        }
    }

    /// <summary>
    /// Player preferences and settings
    /// </summary>
    public class PlayerPreferences
    {
        // Audio settings
        public float MasterVolume { get; set; } = 1.0f;
        public float MusicVolume { get; set; } = 0.8f;
        public float SfxVolume { get; set; } = 1.0f;

        // Visual settings
        public bool FullScreen { get; set; } = false;
        public int ResolutionWidth { get; set; } = 1200;
        public int ResolutionHeight { get; set; } = 800;
        public bool ShowFPS { get; set; } = false;
        public bool VSync { get; set; } = true;

        // Gameplay settings
        public float CameraSmoothness { get; set; } = 5.0f;
        public bool ShowMinimap { get; set; } = true;
        public bool ShowHealthBar { get; set; } = true;
        public bool AutoSave { get; set; } = true;

        // Control settings (could be expanded for key binding)
        public bool InvertYAxis { get; set; } = false;
        public float MouseSensitivity { get; set; } = 1.0f;

        // Accessibility
        public bool ColorBlindMode { get; set; } = false;
        public float UIScale { get; set; } = 1.0f;
        public bool HighContrast { get; set; } = false;
    }
}