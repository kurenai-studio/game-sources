using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Manages persistent game settings: resolution, VSync, vibration, window mode.
    /// All values are saved/loaded through PlayerPrefs.
    /// Vibration covers both camera screen-shake and gamepad rumble.
    /// </summary>
    public class SettingsManager : MonoBehaviour
    {
        public static SettingsManager Instance { get; private set; }

        /// <summary>
        /// True when vibration (camera shake + gamepad rumble) is allowed.
        /// Defaults to on if the manager has not spawned yet.
        /// </summary>
        public static bool IsVibrationOn => Instance == null || Instance.VibrationEnabled;

        // Available resolutions (common 16:9 choices)
        public static readonly Vector2Int[] Resolutions = new Vector2Int[]
        {
            new Vector2Int(1280, 720),
            new Vector2Int(1366, 768),
            new Vector2Int(1600, 900),
            new Vector2Int(1920, 1080),
            new Vector2Int(2560, 1440),
            new Vector2Int(3840, 2160),
        };

        public int CurrentResolutionIndex { get; private set; }
        public bool VSyncEnabled { get; private set; }
        public bool VibrationEnabled { get; private set; }
        public bool IsFullscreen { get; private set; }

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            LoadSettings();
            ApplyAllSettings();
        }

        // ── Persistence ──────────────────────────────────────────

        private void LoadSettings()
        {
            // Resolution – default to current screen or 1920×1080
            int defaultRes = FindClosestResolutionIndex(Screen.width, Screen.height);
            CurrentResolutionIndex = PlayerPrefs.GetInt("Settings_ResIndex", defaultRes);
            CurrentResolutionIndex = Mathf.Clamp(CurrentResolutionIndex, 0, Resolutions.Length - 1);

            VSyncEnabled   = PlayerPrefs.GetInt("Settings_VSync", 1) == 1;
            VibrationEnabled = PlayerPrefs.GetInt("Settings_Vibration", 1) == 1;
            IsFullscreen   = PlayerPrefs.GetInt("Settings_Fullscreen", 1) == 1;
        }

        private void SaveSettings()
        {
            PlayerPrefs.SetInt("Settings_ResIndex", CurrentResolutionIndex);
            PlayerPrefs.SetInt("Settings_VSync", VSyncEnabled ? 1 : 0);
            PlayerPrefs.SetInt("Settings_Vibration", VibrationEnabled ? 1 : 0);
            PlayerPrefs.SetInt("Settings_Fullscreen", IsFullscreen ? 1 : 0);
            PlayerPrefs.Save();
        }

        // ── Public Setters ───────────────────────────────────────

        public void SetResolution(int index)
        {
            CurrentResolutionIndex = Mathf.Clamp(index, 0, Resolutions.Length - 1);
            ApplyResolution();
            SaveSettings();
        }

        public void NextResolution()
        {
            SetResolution((CurrentResolutionIndex + 1) % Resolutions.Length);
        }

        public void PrevResolution()
        {
            SetResolution((CurrentResolutionIndex - 1 + Resolutions.Length) % Resolutions.Length);
        }

        public void ToggleVSync()
        {
            VSyncEnabled = !VSyncEnabled;
            ApplyVSync();
            SaveSettings();
        }

        public void ToggleVibration()
        {
            VibrationEnabled = !VibrationEnabled;
            if (!VibrationEnabled)
            {
                CameraFollow.Instance?.StopShake();
#if ENABLE_INPUT_SYSTEM
                var gp = UnityEngine.InputSystem.Gamepad.current;
                if (gp != null) gp.SetMotorSpeeds(0f, 0f);
#endif
            }
            SaveSettings();
        }

        public void ToggleFullscreen()
        {
            IsFullscreen = !IsFullscreen;
            ApplyResolution(); // resolution call includes fullscreen flag
            SaveSettings();
        }

        // ── Apply ────────────────────────────────────────────

        private void ApplyAllSettings()
        {
            ApplyResolution();
            ApplyVSync();
        }

        private void ApplyResolution()
        {
            var res = Resolutions[CurrentResolutionIndex];
            FullScreenMode mode = IsFullscreen
                ? FullScreenMode.FullScreenWindow
                : FullScreenMode.Windowed;
            Screen.SetResolution(res.x, res.y, mode);
        }

        private void ApplyVSync()
        {
            QualitySettings.vSyncCount = VSyncEnabled ? 1 : 0;
        }

        // ── Helpers ────────────────────────────────────────

        public string CurrentResolutionLabel()
        {
            var r = Resolutions[CurrentResolutionIndex];
            return $"{r.x} x {r.y}";
        }

        private int FindClosestResolutionIndex(int w, int h)
        {
            int bestIndex = 3; // 1920×1080 fallback
            int bestDiff = int.MaxValue;
            for (int i = 0; i < Resolutions.Length; i++)
            {
                int diff = Mathf.Abs(Resolutions[i].x - w) + Mathf.Abs(Resolutions[i].y - h);
                if (diff < bestDiff)
                {
                    bestDiff = diff;
                    bestIndex = i;
                }
            }
            return bestIndex;
        }

        /// <summary>Call this from gameplay code instead of raw gamepad rumble,
        /// so vibration respects the player's setting.</summary>
        public static void TryVibrate(float lowFreq, float highFreq, float duration)
        {
            if (!IsVibrationOn) return;

#if ENABLE_INPUT_SYSTEM
            var gp = UnityEngine.InputSystem.Gamepad.current;
            if (gp != null && Instance != null)
            {
                gp.SetMotorSpeeds(lowFreq, highFreq);
                Instance.StartCoroutine(StopVibrationAfter(duration));
            }
#endif
        }

#if ENABLE_INPUT_SYSTEM
        private static System.Collections.IEnumerator StopVibrationAfter(float t)
        {
            yield return new WaitForSecondsRealtime(t);
            var gp = UnityEngine.InputSystem.Gamepad.current;
            if (gp != null) gp.SetMotorSpeeds(0f, 0f);
        }
#endif
    }
}
