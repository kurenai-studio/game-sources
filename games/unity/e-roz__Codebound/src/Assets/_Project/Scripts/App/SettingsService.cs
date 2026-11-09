using System;
using System.IO;
using Codebound.Core;
using UnityEngine;

namespace Codebound.App
{
    public class SettingsService
    {
        const string FileName = "settings.json";

        readonly string _directory;

        public SettingsData Settings { get; private set; } = new SettingsData();

        public event Action Changed;

        public SettingsService(string directory)
        {
            _directory = directory;
        }

        string SettingsPath => Path.Combine(_directory, FileName);

        public void Load()
        {
            Settings = ReadOrDefault();
        }

        public void Save()
        {
            Directory.CreateDirectory(_directory);
            File.WriteAllText(SettingsPath, JsonUtility.ToJson(Settings, true));
        }

        public void SetMusicVolume(float value)
        {
            Settings.musicVolume = SettingsData.ClampVolume(value);
            Changed?.Invoke();
        }

        public void SetSfxVolume(float value)
        {
            Settings.sfxVolume = SettingsData.ClampVolume(value);
            Changed?.Invoke();
        }

        SettingsData ReadOrDefault()
        {
            if (!File.Exists(SettingsPath)) return new SettingsData();

            try
            {
                var parsed = JsonUtility.FromJson<SettingsData>(File.ReadAllText(SettingsPath));
                if (parsed == null) return new SettingsData();
                parsed.Clamp();
                return parsed;
            }
            catch (Exception e) when (e is ArgumentException || e is IOException || e is UnauthorizedAccessException)
            {
                return new SettingsData();
            }
        }
    }
}
