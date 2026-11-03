using Snake.Core.Storages.Interfaces;
using System;
using System.Diagnostics;

namespace Snake.Core.Managers
{
    /// <summary>
    /// Manages loading and saving of game settings.
    /// </summary>
    /// <typeparam name="T">The type of settings to manage.</typeparam>
    public class SettingsManager<T> where T : new()
    {
        /// <summary>
        /// The storage implementation used by this manager.
        /// </summary>
        private readonly ISettingsStorage storage;
        
        /// <summary>
        /// The current settings instance.
        /// </summary>
        private T settings;

        /// <summary>
        /// Occurs when settings are loaded.
        /// </summary>
        public event Action<T> SettingsLoaded;

        /// <summary>
        /// Occurs when settings are saved.
        /// </summary>
        public event Action<T> SettingsSaved;

        /// <summary>
        /// Gets the storage implementation used by this manager.
        /// </summary>
        public ISettingsStorage Storage => storage;

        /// <summary>
        /// Gets the current settings instance.
        /// </summary>
        public T Settings => settings;

        /// <summary>
        /// Initializes a new instance of the SettingsManager class.
        /// </summary>
        /// <param name="storage">The storage implementation to use.</param>
        /// <exception cref="ArgumentNullException">Thrown when storage is null.</exception>
        public SettingsManager(ISettingsStorage storage)
        {
            ArgumentNullException.ThrowIfNull(storage);

            this.storage = storage;

            // Load the settings
            Load();
        }

        /// <summary>
        /// Saves the current settings to storage.
        /// </summary>
        public void Save()
        {
            // Try to load the settings
            try
            {
                // Save the settings
                storage.SaveSettings(settings);

                // Invoke the settings saved event
                SettingsSaved?.Invoke(settings);
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to save settings: {ex}");
            }
        }

        /// <summary>
        /// Loads settings from storage, or creates default settings if loading fails.
        /// </summary>
        public void Load()
        {
            try
            {
                // Load the settings
                settings = storage.LoadSettings<T>() ?? new T();
            }
            catch (Exception)
            {
                // If loading fails, initialize with default settings
                settings = new T();
            }

            // Invoke the settings loaded event
            SettingsLoaded?.Invoke(settings);
        }
    }
}
