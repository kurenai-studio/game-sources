using System;

namespace Codebound.Core
{
    [Serializable]
    public class SettingsData
    {
        public const float DefaultVolume = 0.8f;

        public float musicVolume = DefaultVolume;
        public float sfxVolume = DefaultVolume;

        public void Clamp()
        {
            musicVolume = ClampVolume(musicVolume);
            sfxVolume = ClampVolume(sfxVolume);
        }

        public static float ClampVolume(float value)
        {
            if (float.IsNaN(value)) return DefaultVolume;
            return Math.Max(0f, Math.Min(1f, value));
        }
    }
}
