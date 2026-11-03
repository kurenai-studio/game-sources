using System;
using System.Collections.Generic;
using System.Globalization;

namespace QapaqInqa.Core
{
    /// <summary>Key-value storage for records and settings (PlayerPrefs in the game, memory in tests).</summary>
    public interface IKeyValueStore
    {
        int GetInt(string key, int fallback);
        float GetFloat(string key, float fallback);
        void SetInt(string key, int value);
        void SetFloat(string key, float value);
        void Save();
    }

    public sealed class MemoryStore : IKeyValueStore
    {
        readonly Dictionary<string, string> values = new Dictionary<string, string>();

        public int SaveCount { get; private set; }

        public int GetInt(string key, int fallback) =>
            values.TryGetValue(key, out string text) && int.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out int value) ? value : fallback;

        public float GetFloat(string key, float fallback) =>
            values.TryGetValue(key, out string text) && float.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out float value) ? value : fallback;

        public void SetInt(string key, int value) => values[key] = value.ToString(CultureInfo.InvariantCulture);

        public void SetFloat(string key, float value) => values[key] = value.ToString("R", CultureInfo.InvariantCulture);

        public void Save() => SaveCount++;
    }

    /// <summary>
    /// The best campaign score, the best time per level and how far the player has got (which
    /// levels the level select offers). Only improvements are written.
    /// </summary>
    public sealed class Records
    {
        public const string BestScoreKey = "QapaqInqa.BestScore";
        public const string ReachedKey = "QapaqInqa.LevelsReached";
        public const string BestTimeKeyPrefix = "QapaqInqa.BestTime.";
        public const string BestRunKey = "QapaqInqa.BestRunTime";

        readonly IKeyValueStore store;

        public Records(IKeyValueStore store)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
        }

        public int BestScore => Math.Max(0, store.GetInt(BestScoreKey, 0));

        /// <summary>How many levels the level select offers (always at least the first).</summary>
        public int LevelsReached => Math.Max(1, Math.Min(Levels.All.Count, store.GetInt(ReachedKey, 1)));

        /// <summary>Seconds of the fastest clear of a level, or 0 when it was never cleared.</summary>
        public float BestTime(int level)
        {
            float time = store.GetFloat(BestTimeKeyPrefix + level, 0f);
            return time > 0f ? time : 0f;
        }

        /// <summary>Seconds of the fastest full campaign, or 0 when it was never finished.</summary>
        public float BestRunTime
        {
            get
            {
                float time = store.GetFloat(BestRunKey, 0f);
                return time > 0f ? time : 0f;
            }
        }

        public bool IsUnlocked(int level) => level >= 0 && level < LevelsReached;

        /// <summary>Records a level clear. Returns true when the time beat the previous best.</summary>
        public bool SubmitClear(int level, float seconds)
        {
            if (level < 0 || level >= Levels.All.Count) throw new ArgumentOutOfRangeException(nameof(level));
            bool changed = false;
            int reached = Math.Min(Levels.All.Count, level + 2);
            if (reached > LevelsReached)
            {
                store.SetInt(ReachedKey, reached);
                changed = true;
            }
            float best = BestTime(level);
            bool newBest = seconds > 0f && (best <= 0f || seconds < best);
            if (newBest)
            {
                store.SetFloat(BestTimeKeyPrefix + level, seconds);
                changed = true;
            }
            if (changed) store.Save();
            return newBest;
        }

        /// <summary>Records a finished run's score. Returns true when it beat the previous best.</summary>
        public bool SubmitScore(int score)
        {
            if (score <= BestScore) return false;
            store.SetInt(BestScoreKey, score);
            store.Save();
            return true;
        }

        /// <summary>Records a full campaign's time. Returns true when it beat the previous best.</summary>
        public bool SubmitRunTime(float seconds)
        {
            float best = BestRunTime;
            if (seconds <= 0f || (best > 0f && seconds >= best)) return false;
            store.SetFloat(BestRunKey, seconds);
            store.Save();
            return true;
        }

        /// <summary>"1:05.3", or "--:--" for no time.</summary>
        public static string FormatTime(float seconds)
        {
            if (seconds <= 0f) return "--:--";
            int tenths = (int)Math.Round(seconds * 10f, MidpointRounding.AwayFromZero);
            int minutes = tenths / 600;
            float rest = (tenths % 600) / 10f;
            return minutes.ToString(CultureInfo.InvariantCulture) + ":" + rest.ToString("00.0", CultureInfo.InvariantCulture);
        }
    }

    /// <summary>Player options, clamped and persisted. Volumes go from 0 to 10.</summary>
    public sealed class Settings
    {
        public const int MaxVolume = 10;
        const string MusicKey = "QapaqInqa.MusicVolume";
        const string EffectsKey = "QapaqInqa.EffectsVolume";
        const string ShakeKey = "QapaqInqa.ScreenShake";
        const string TimerKey = "QapaqInqa.ShowTimer";

        readonly IKeyValueStore store;

        public Settings(IKeyValueStore store)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            MusicVolume = Clamp(store.GetInt(MusicKey, 7));
            EffectsVolume = Clamp(store.GetInt(EffectsKey, 8));
            ScreenShake = store.GetInt(ShakeKey, 1) != 0;
            ShowTimer = store.GetInt(TimerKey, 1) != 0;
        }

        public int MusicVolume { get; private set; }
        public int EffectsVolume { get; private set; }
        public bool ScreenShake { get; private set; }
        public bool ShowTimer { get; private set; }

        public float MusicGain => MusicVolume / (float)MaxVolume;
        public float EffectsGain => EffectsVolume / (float)MaxVolume;

        public void StepMusic(int delta)
        {
            MusicVolume = Clamp(MusicVolume + delta);
            Persist();
        }

        public void StepEffects(int delta)
        {
            EffectsVolume = Clamp(EffectsVolume + delta);
            Persist();
        }

        public void ToggleShake()
        {
            ScreenShake = !ScreenShake;
            Persist();
        }

        public void ToggleTimer()
        {
            ShowTimer = !ShowTimer;
            Persist();
        }

        void Persist()
        {
            store.SetInt(MusicKey, MusicVolume);
            store.SetInt(EffectsKey, EffectsVolume);
            store.SetInt(ShakeKey, ScreenShake ? 1 : 0);
            store.SetInt(TimerKey, ShowTimer ? 1 : 0);
            store.Save();
        }

        static int Clamp(int volume) => Math.Max(0, Math.Min(MaxVolume, volume));
    }
}
