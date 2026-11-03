using Snake.Core.Localization;
using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Snake.Core.Settings
{
    /// <summary>
    /// Represents the game settings that can be saved and loaded.
    /// </summary>
    public class GameSettings : INotifyPropertyChanged
    {
        private string language = LocalizationManager.DEFAULT_CULTURE_CODE;
        private bool musicEnabled = true;
        private bool soundEffectsEnabled = true;

        /// <summary>
        /// Occurs when a property value changes.
        /// </summary>
        public event PropertyChangedEventHandler PropertyChanged;

        /// <summary>
        /// Gets or sets the language code for localization (e.g., "en-US").
        /// </summary>
        public string Language
        {
            get => language;
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    throw new ArgumentException("Language cannot be null or whitespace.", nameof(value));
                
                SetProperty(ref language, value);
            }
        }

        /// <summary>
        /// Gets or sets whether background music is enabled.
        /// </summary>
        public bool MusicEnabled
        {
            get => musicEnabled;
            set => SetProperty(ref musicEnabled, value);
        }

        /// <summary>
        /// Gets or sets whether sound effects are enabled.
        /// </summary>
        public bool SoundEffectsEnabled
        {
            get => soundEffectsEnabled;
            set => SetProperty(ref soundEffectsEnabled, value);
        }

        /// <summary>
        /// Sets the property value and raises the PropertyChanged event if the value has changed.
        /// </summary>
        /// <typeparam name="T">The type of the property.</typeparam>
        /// <param name="field">The backing field for the property.</param>
        /// <param name="value">The new value for the property.</param>
        /// <param name="propertyName">The name of the property (automatically provided by the compiler).</param>
        /// <returns>True if the property was changed, false otherwise.</returns>
        protected bool SetProperty<T>(ref T field, T value, [CallerMemberName] string propertyName = null)
        {
            if (Equals(field, value))
                return false;

            field = value;
            OnPropertyChanged(propertyName);
            return true;
        }

        /// <summary>
        /// Raises the PropertyChanged event.
        /// </summary>
        /// <param name="propertyName">The name of the property that changed (automatically provided by the compiler).</param>
        protected void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
