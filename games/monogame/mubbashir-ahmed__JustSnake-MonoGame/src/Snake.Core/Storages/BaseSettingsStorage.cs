using Snake.Core.Localization;
using Snake.Core.Storages.Interfaces;
using System;
using System.IO;
using System.Text.Json;

namespace Snake.Core.Storages
{
    /// <summary>
    /// Base class for settings storage implementations.
    /// </summary>
    public abstract class BaseSettingsStorage : ISettingsStorage
    {
        /// <summary>
        /// The name of the settings file.
        /// </summary>
        private string settingsFileName;

        /// <summary>
        /// The name of the leaderboard file.
        /// </summary>
        private string leaderboardFileName;

        /// <summary>
        /// The cached path to the settings file.
        /// </summary>
        private string cachedSettingsFilePath;

        /// <summary>
        /// The cached path to the leaderboard file.
        /// </summary>
        private string cachedLeaderboardFilePath;

        /// <summary>
        /// The JSON serializer options.
        /// </summary>
        private static readonly JsonSerializerOptions JsonOptions = new JsonSerializerOptions { WriteIndented = true };

        /// <summary>
        /// The name of the application folder.
        /// </summary>
        private readonly string AppFolderName = Resources.GameTitle.Replace(" ", "");
        
        /// <summary>
        /// The default name of the settings file.
        /// </summary>
        private const string DefaultSettingsFileName = "settings.json";

        /// <summary>
        /// The default name of the leaderboard file.
        /// </summary>
        private const string DefaultLeaderboardFileName = "leaderboard.json";

        /// <summary>
        /// The special folder path for the settings.
        /// </summary>
        protected abstract Environment.SpecialFolder SpecialFolderPath { get; }

        /// <summary>
        /// The name of the settings file.
        /// </summary>
        public string SettingsFileName
        {
            get => settingsFileName;
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    throw new ArgumentException("Settings file name cannot be null or whitespace.", nameof(value));
                
                if (settingsFileName != value)
                {
                    settingsFileName = value;
                    cachedSettingsFilePath = null;
                }
            }
        }

        /// <summary>
        /// The path to the settings file.
        /// </summary>
        protected string SettingsFilePath
        {
            get
            {
                if (cachedSettingsFilePath == null)
                {
                    cachedSettingsFilePath = Path.Combine(
                        Environment.GetFolderPath(SpecialFolderPath),
                        AppFolderName,
                        SettingsFileName
                    );
                }
                return cachedSettingsFilePath;
            }
        }

        /// <summary>
        /// The name of the leaderboard file.
        /// </summary>
        public string LeaderboardFileName 
        {
            get => leaderboardFileName;
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    throw new ArgumentException("Leaderboard file name cannot be null or whitespace.", nameof(value));

                if (leaderboardFileName != value)
                {
                    leaderboardFileName = value;
                    cachedLeaderboardFilePath = null;
                }
            }
        }

        /// <summary>
        /// The path to the leaderboard file.
        /// </summary>
        protected string LeaderboardFilePath
        {
            get
            {
                if (cachedLeaderboardFilePath == null)
                {
                    cachedLeaderboardFilePath = Path.Combine(
                        Environment.GetFolderPath(SpecialFolderPath), 
                        AppFolderName, 
                        LeaderboardFileName
                    );
                }

                return cachedLeaderboardFilePath;
            }
        }

        /// <summary>
        /// Initializes a new instance of the BaseSettingsStorage class.
        /// </summary>
        protected BaseSettingsStorage()
        {
            settingsFileName = DefaultSettingsFileName;
            leaderboardFileName = DefaultLeaderboardFileName;
        }

        /// <summary>
        /// Saves the settings to the file.
        /// </summary>
        /// <typeparam name="T">The type of the settings.</typeparam>
        /// <param name="settings">The settings to save.</param>
        public virtual void SaveSettings<T>(T settings) where T : new()
        {
            ArgumentNullException.ThrowIfNull(settings);

            string jsonString = JsonSerializer.Serialize(settings, JsonOptions);
            string directoryPath = Path.GetDirectoryName(SettingsFilePath);

            if (!string.IsNullOrEmpty(directoryPath) && !Directory.Exists(directoryPath))
            {
                Directory.CreateDirectory(directoryPath);
            }

            File.WriteAllText(SettingsFilePath, jsonString);
        }

        /// <summary>
        /// Loads the settings from the file.
        /// </summary>
        /// <typeparam name="T">The type of the settings.</typeparam>
        /// <returns>The loaded settings.</returns>
        public virtual T LoadSettings<T>() where T : new()
        {
            if (!IsFileExist(SettingsFilePath))
                return new T();

            try
            {
                string jsonString = File.ReadAllText(SettingsFilePath);
                return JsonSerializer.Deserialize<T>(jsonString) ?? new T();
            }
            catch (JsonException)
            {
                // If JSON is corrupted, return default settings
                return new T();
            }
        }

        /// <summary>
        /// Loads the leaderboard from the file.
        /// </summary>
        /// <typeparam name="T">The type of the leaderboard.</typeparam>
        /// <returns>The loaded leaderboard.</returns>
        public virtual T LoadLeaderboard<T>() where T : new()
        {
            if (!IsFileExist(LeaderboardFilePath))
                return new T();

            try
            {
                string jsonString = File.ReadAllText(LeaderboardFilePath);
                return JsonSerializer.Deserialize<T>(jsonString) ?? new T();
            }
            catch (JsonException)
            {
                // If JSON is corrupted, return default leaderboard
                return new T();
            }
        }

        /// <summary>
        /// Saves the leaderboard to the file.
        /// </summary>
        /// <typeparam name="T">The type of the leaderboard.</typeparam>
        /// <param name="leaderboard">The leaderboard to save.</param>
        public virtual void SaveLeaderboard<T>(T leaderboard) where T : new()
        {
            ArgumentNullException.ThrowIfNull(leaderboard);

            string jsonString = JsonSerializer.Serialize(leaderboard, JsonOptions);
            string directoryPath = Path.GetDirectoryName(LeaderboardFilePath);

            if (!string.IsNullOrEmpty(directoryPath) && !Directory.Exists(directoryPath))
            {
                Directory.CreateDirectory(directoryPath);
            }

            File.WriteAllText(LeaderboardFilePath, jsonString);
        }

        /// <summary>
        /// Checks if the file exists.
        /// </summary>
        /// <param name="filePath">The path to the file.</param>
        /// <returns>True if the file exists, false otherwise.</returns>
        public bool IsFileExist(string filePath)
        {
            return !string.IsNullOrEmpty(filePath) && File.Exists(filePath);
        }
    }
}

