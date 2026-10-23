using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Tạo sprite pixel-art 12x12 bằng code cho từng ô trang bị và từng loại vũ khí.
    /// Ảnh là xám + viền đen, màu độ hiếm được nhân lên bằng SpriteRenderer.color.
    /// '.' = trong suốt, 'o' = viền, '#' = sáng, '+' = trung bình.
    /// Vũ khí được vẽ thẳng đứng, mũi hướng lên trên.
    /// </summary>
    public static class EquipmentIcons
    {
        private static readonly Dictionary<string, Sprite> _cache = new Dictionary<string, Sprite>();

        private static readonly string[] SwordArt =
        {
            ".....oo.....",
            "....o##o....",
            "....o##o....",
            "....o##o....",
            "....o##o....",
            "....o##o....",
            "..oooooooo..",
            "..o++++++o..",
            "..oooooooo..",
            ".....o++o...",
            ".....o++o...",
            "....oooooo..",
        };

        private static readonly string[] BladeArt =
        {
            "......oo....",
            ".....o##o...",
            "....o###o...",
            "....o###o...",
            "....o###o...",
            "....o###o...",
            ".....o##o...",
            "...oooooo...",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....oooo....",
        };

        private static readonly string[] AxeArt =
        {
            "....oooo....",
            "...o####oo..",
            "...o######o.",
            "...o######o.",
            "...o####oo..",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....oooo....",
        };

        private static readonly string[] SpearArt =
        {
            ".....oo.....",
            "....o##o....",
            "...o####o...",
            "....o##o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....o++o....",
            "....oooo....",
        };

        private static readonly string[] ArmorArt =
        {
            "..oo....oo..",
            ".o##oooo##o.",
            ".o########o.",
            ".o########o.",
            "..o##++##o..",
            "..o##++##o..",
            "..o##++##o..",
            "..o######o..",
            "..o######o..",
            "..o##oo##o..",
            "..o#o..o#o..",
            "..ooo..ooo..",
        };

        private static readonly string[] BootsArt =
        {
            "............",
            "..oooo......",
            "..o##o......",
            "..o##o......",
            "..o##o......",
            "..o##o......",
            "..o##oooo...",
            "..o######o..",
            "..o#######o.",
            "..oooooooooo",
            "............",
            "............",
        };

        private static readonly string[] RingArt =
        {
            "............",
            "....oooo....",
            "...o####o...",
            "....oooo....",
            "..oo....oo..",
            ".o#o....o#o.",
            ".o#o....o#o.",
            ".o#o....o#o.",
            "..o##..##o..",
            "...o####o...",
            "....oooo....",
            "............",
        };

        /// <summary>Hình theo ô trang bị (vũ khí mặc định là kiếm).</summary>
        public static Sprite Get(EquipSlot slot)
        {
            switch (slot)
            {
                case EquipSlot.Weapon: return GetWeapon(WeaponType.Sword);
                case EquipSlot.Armor: return GetCached("Armor", ArmorArt);
                case EquipSlot.Boots: return GetCached("Boots", BootsArt);
                default: return GetCached("Ring", RingArt);
            }
        }

        /// <summary>Hình theo đúng món đồ (vũ khí có hình riêng theo loại).</summary>
        public static Sprite Get(EquipmentItem item)
        {
            if (item == null) return null;
            if (item.slot == EquipSlot.Weapon) return GetWeapon(item.weaponType);
            return Get(item.slot);
        }

        public static Sprite GetWeapon(WeaponType type)
        {
            switch (type)
            {
                case WeaponType.Blade: return GetCached("W_Blade", BladeArt);
                case WeaponType.Axe: return GetCached("W_Axe", AxeArt);
                case WeaponType.Spear: return GetCached("W_Spear", SpearArt);
                default: return GetCached("W_Sword", SwordArt);
            }
        }

        private static Sprite GetCached(string key, string[] art)
        {
            if (_cache.TryGetValue(key, out var cached) && cached != null) return cached;
            var sprite = Build(art);
            _cache[key] = sprite;
            return sprite;
        }

        private static Sprite Build(string[] art)
        {
            int h = art.Length;
            int w = art[0].Length;

            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.filterMode = FilterMode.Point;
            tex.wrapMode = TextureWrapMode.Clamp;

            var clear = new Color(0, 0, 0, 0);
            var outline = new Color(0.12f, 0.12f, 0.12f, 1f);
            var light = Color.white;
            var mid = new Color(0.65f, 0.65f, 0.65f, 1f);

            for (int row = 0; row < h; row++)
            {
                for (int x = 0; x < w; x++)
                {
                    Color c;
                    switch (art[row][x])
                    {
                        case 'o': c = outline; break;
                        case '#': c = light; break;
                        case '+': c = mid; break;
                        default: c = clear; break;
                    }
                    tex.SetPixel(x, h - 1 - row, c);
                }
            }
            tex.Apply();

            // pixelsPerUnit = 12 -> sprite rộng/cao đúng 1 đơn vị
            return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.5f), w);
        }
    }
}
