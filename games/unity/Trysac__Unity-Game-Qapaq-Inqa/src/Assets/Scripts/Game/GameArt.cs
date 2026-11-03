using System.Collections.Generic;
using QapaqInqa.Core;
using UnityEngine;

namespace QapaqInqa.Game
{
    /// <summary>
    /// Every texture and clip the game uses, wired up by the editor ProjectBuilder. The textures
    /// are horizontal strips of equal frames drawn by tools/art; <see cref="Frames"/> slices them.
    /// </summary>
    public sealed class GameArt : ScriptableObject
    {
        public const float PixelsPerUnit = 16f;

        [Header("Sheets")]
        public Texture2D Player;
        public Texture2D Walker;
        public Texture2D Bat;
        public Texture2D StonePuma;
        public Texture2D Items;
        public Texture2D Checkpoint;
        public Texture2D SunGate;
        /// <summary>Readable: the level view copies tiles out of it into one texture per level.</summary>
        public Texture2D Tiles;
        public Texture2D Icon;

        [Header("Backgrounds (far, near) per theme: valley, mountain, cave, temple")]
        public Texture2D[] FarBackgrounds = new Texture2D[4];
        public Texture2D[] NearBackgrounds = new Texture2D[4];

        [Header("Music")]
        public AudioClip TitleMusic;
        public AudioClip ValleyMusic;
        public AudioClip MountainMusic;
        public AudioClip CaveMusic;
        public AudioClip BossMusic;

        [Header("Effects")]
        public AudioClip Jump;
        public AudioClip Land;
        public AudioClip Shoot;
        public AudioClip ArrowHit;
        public AudioClip Coin;
        public AudioClip Idol;
        public AudioClip Shell;
        public AudioClip Heart;
        public AudioClip CheckpointLit;
        public AudioClip GateOpen;
        public AudioClip Hurt;
        public AudioClip Die;
        public AudioClip Stomp;
        public AudioClip EnemyDie;
        public AudioClip BossRoar;
        public AudioClip BossSlam;
        public AudioClip BossThrow;
        public AudioClip BossDefeat;
        public AudioClip Clear;
        public AudioClip GameOver;
        public AudioClip Click;
        public AudioClip Confirm;

        readonly Dictionary<Texture2D, Sprite[]> cache = new Dictionary<Texture2D, Sprite[]>();

        /// <summary>Slices a strip into frames of the given width, pivoted at the bottom centre.</summary>
        public Sprite[] Frames(Texture2D sheet, int frameWidth, Vector2? pivot = null)
        {
            if (cache.TryGetValue(sheet, out Sprite[] sprites)) return sprites;
            int count = sheet.width / frameWidth;
            sprites = new Sprite[count];
            for (int i = 0; i < count; i++)
            {
                sprites[i] = Sprite.Create(sheet, new Rect(i * frameWidth, 0, frameWidth, sheet.height),
                    pivot ?? new Vector2(0.5f, 0f), PixelsPerUnit, 0, SpriteMeshType.FullRect);
                sprites[i].name = $"{sheet.name}_{i}";
            }
            cache[sheet] = sprites;
            return sprites;
        }

        public Sprite Whole(Texture2D texture, float pixelsPerUnit = PixelsPerUnit) =>
            Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f), pixelsPerUnit, 0, SpriteMeshType.FullRect);

        public AudioClip Music(Theme theme, bool boss)
        {
            if (boss) return BossMusic;
            switch (theme)
            {
                case Theme.Valley: return ValleyMusic;
                case Theme.Mountain: return MountainMusic;
                case Theme.Cave: return CaveMusic;
                default: return ValleyMusic;
            }
        }
    }

    /// <summary>Frame indices into the generated sheets (see tools/art/build.py).</summary>
    public static class Frame
    {
        public const int PlayerIdle = 0;
        public const int PlayerRun = 2;
        public const int PlayerRunFrames = 6;
        public const int PlayerJump = 8;
        public const int PlayerFall = 9;
        public const int PlayerClimb = 10;
        public const int PlayerShoot = 12;
        public const int PlayerHurt = 13;

        public const int Coin = 0;
        public const int CoinFrames = 6;
        public const int Idol = 6;
        public const int Shell = 8;
        public const int Heart = 9;
        public const int Rock = 10;
        public const int Arrow = 11;
        public const int Sparkle = 12;

        public const int PumaIdle = 0;
        public const int PumaRun = 2;
        public const int PumaCrouch = 6;
        public const int PumaLeap = 7;
        public const int PumaHurt = 8;
    }

    /// <summary>Keeps records and settings in PlayerPrefs (the registry on Windows, IndexedDB on the web).</summary>
    public sealed class PlayerPrefsStore : IKeyValueStore
    {
        public int GetInt(string key, int fallback) => PlayerPrefs.GetInt(key, fallback);
        public float GetFloat(string key, float fallback) => PlayerPrefs.GetFloat(key, fallback);
        public void SetInt(string key, int value) => PlayerPrefs.SetInt(key, value);
        public void SetFloat(string key, float value) => PlayerPrefs.SetFloat(key, value);
        public void Save() => PlayerPrefs.Save();
    }
}
