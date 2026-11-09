using UnityEngine;

namespace Codebound.App
{
    public static class GameServices
    {
        static SaveService _save;
        static SettingsService _settings;

        public static SaveService Save => _save ??= new SaveService(Application.persistentDataPath);

        public static SettingsService Settings
        {
            get
            {
                if (_settings != null) return _settings;
                _settings = new SettingsService(Application.persistentDataPath);
                _settings.Load();
                return _settings;
            }
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        static void Reset()
        {
            _save = null;
            _settings = null;
        }
    }
}
