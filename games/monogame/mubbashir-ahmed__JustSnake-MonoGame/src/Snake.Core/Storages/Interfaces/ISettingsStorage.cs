namespace Snake.Core.Storages.Interfaces
{
    /// <summary>
    /// Interface for settings storage implementations.
    /// </summary>
    public interface ISettingsStorage
    {
        /// <summary>
        /// The name of the settings file.
        /// </summary>
        string SettingsFileName { get; set; }

        /// <summary>
        /// The name of the leaderboard file.
        /// </summary>
        string LeaderboardFileName { get; set; }
        
        /// <summary>
        /// Saves the settings to the file.
        /// </summary>
        /// <typeparam name="T">The type of the settings.</typeparam>
        /// <param name="settings">The settings to save.</param>
        void SaveSettings<T>(T settings) where T : new();

        /// <summary>
        /// Loads the settings from the file.
        /// </summary>
        /// <typeparam name="T">The type of the settings.</typeparam>
        /// <returns>The loaded settings.</returns>
        T LoadSettings<T>() where T : new();

        /// <summary>
        /// Loads the leaderboard from the file.
        /// </summary>
        /// <typeparam name="T">The type of the leaderboard.</typeparam>
        /// <returns>The loaded leaderboard.</returns>
        T LoadLeaderboard<T>() where T : new();

        /// <summary>
        /// Saves the leaderboard to the file.
        /// </summary>
        /// <typeparam name="T">The type of the leaderboard.</typeparam>
        /// <param name="leaderboard">The leaderboard to save.</param>
        void SaveLeaderboard<T>(T leaderboard) where T : new();

        /// <summary>
        /// Checks if the file exists.
        /// </summary>
        /// <param name="filePath">The path to the file.</param>
        /// <returns>True if the file exists, false otherwise.</returns>
        bool IsFileExist(string filePath);
    }
}
