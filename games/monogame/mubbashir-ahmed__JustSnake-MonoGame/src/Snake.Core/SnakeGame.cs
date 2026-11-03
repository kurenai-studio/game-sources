using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Media;
using Snake.Core.Graphics;
using Snake.Core.Localization;
using Snake.Core.Managers;
using Snake.Core.Screens;
using Snake.Core.Settings;
using Snake.Core.Storages;
using Snake.Core.Storages.Interfaces;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Linq;

namespace Snake.Core
{
    /// <summary>
    /// The main class for the game, responsible for managing game components, settings, 
    /// and platform-specific configurations.
    /// </summary>
    public class SnakeGame : Game
    {
        /// <summary>
        /// The screen manager for the game.
        /// </summary>
        private readonly ScreenManager screenManager;

        /// <summary>
        /// The settings manager for the game.
        /// </summary>
        public static SettingsManager<GameSettings> SettingsManager;
        
        /// <summary>
        /// The leaderboard manager for the game.
        /// </summary>
        public static LeaderboardManager<Leaderboard> LeaderboardManager;

        /// <summary>
        /// The background music for the game.
        /// </summary>
        private readonly Music<Song> backgroundMusic;

        /// <summary>
        /// The path to the background music.
        /// </summary>
        private readonly string backgroundMusicPath = Path.Combine("Audios", "background-music");

        /// <summary>
        /// The property name for the music enabled property.
        /// </summary>
        private const string MusicEnabledPropertyName = nameof(GameSettings.MusicEnabled);

        /// <summary>
        /// The graphics device manager for the game.
        /// </summary>
        public GraphicsDeviceManager GraphicsDeviceManager { get; private set; }

        /// <summary>
        /// Indicates if the game is running on a mobile platform.
        /// </summary>
        public readonly static bool IsMobile = OperatingSystem.IsAndroid() || OperatingSystem.IsIOS();

        /// <summary>
        /// Indicates if the game is running on a desktop platform.
        /// </summary>
        public readonly static bool IsDesktop = OperatingSystem.IsMacOS() || OperatingSystem.IsLinux() || OperatingSystem.IsWindows();

        /// <summary>
        /// Initializes a new instance of the game. Configures platform-specific settings, 
        /// initializes services like settings and leaderboard managers, and sets up the 
        /// screen manager for screen transitions.
        /// </summary>
        public SnakeGame()
        {
            GraphicsDeviceManager = new GraphicsDeviceManager(this);
            
            Window.Title = Resources.GameTitle;
            GraphicsDeviceManager.PreferredBackBufferWidth = 800;
            GraphicsDeviceManager.PreferredBackBufferHeight = 800;
            GraphicsDeviceManager.SupportedOrientations = DisplayOrientation.LandscapeLeft | DisplayOrientation.LandscapeRight;

            Services.AddService(typeof(GraphicsDeviceManager), GraphicsDeviceManager);

            ISettingsStorage storage;
            if (IsMobile)
            {
                storage = new MobileSettingsStorage();
                GraphicsDeviceManager.IsFullScreen = true;
                IsMouseVisible = false;
            }
            else if (IsDesktop)
            {
                storage = new DesktopSettingsStorage();
                GraphicsDeviceManager.IsFullScreen = false;
                IsMouseVisible = true;
            }
            else
            {
                throw new PlatformNotSupportedException();
            }

            SettingsManager = new SettingsManager<GameSettings>(storage);
            Services.AddService(typeof(SettingsManager<GameSettings>), SettingsManager);

            LeaderboardManager = new LeaderboardManager<Leaderboard>(storage);
            Services.AddService(typeof(LeaderboardManager<Leaderboard>), LeaderboardManager);

            Content.RootDirectory = "Content";

            screenManager = new ScreenManager(this);
            Components.Add(screenManager);

            backgroundMusic = new Music<Song>(backgroundMusicPath, true);
        }

        /// <summary>
        /// Initializes the game, including setting up localization, adding the 
        /// background screen and adding the initial screens to the ScreenManager.
        /// </summary>
        protected override void Initialize()
        {
            base.Initialize();

            List<CultureInfo> cultures = LocalizationManager.GetSupportedCultures();
            string settingsLanguage = SettingsManager.Settings.Language;
            CultureInfo selectedCulture = cultures.FirstOrDefault(x => x.Name == settingsLanguage);
            
            string selectedLanguage = selectedCulture?.Name ?? LocalizationManager.DEFAULT_CULTURE_CODE;
            
            if (selectedCulture == null)
            {
                SettingsManager.Settings.Language = LocalizationManager.DEFAULT_CULTURE_CODE;
            }
            
            LocalizationManager.SetCulture(selectedLanguage);

            screenManager.AddScreen(new BackgroundScreen(), null);
            screenManager.AddScreen(new MainMenuScreen(), null);
        }

        /// <summary>
        /// Loads game content, such as textures and music.
        /// </summary>
        protected override void LoadContent()
        {
            base.LoadContent();

            backgroundMusic.LoadContent(Content);

            SettingsManager.Settings.PropertyChanged += OnSettingsPropertyChanged;

            UpdateMusicState();
        }

        /// <summary>
        /// Handles the property changed event for the music enabled property.
        /// </summary>
        /// <param name="sender">The object that raised the event.</param>
        /// <param name="e">The event arguments.</param>
        private void OnSettingsPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == MusicEnabledPropertyName)
            {
                UpdateMusicState();
            }
        }

        /// <summary>
        /// Updates the music state based on the music enabled setting.
        /// </summary>
        private void UpdateMusicState()
        {
            if (SettingsManager.Settings.MusicEnabled)
                backgroundMusic.Play();
            else
                backgroundMusic.Stop();
        }
    }
}