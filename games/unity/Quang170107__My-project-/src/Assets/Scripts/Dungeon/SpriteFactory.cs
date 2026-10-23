using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    public static class SpriteFactory
    {
        private static readonly Dictionary<string, Sprite> _cache = new Dictionary<string, Sprite>();

        public static Sprite GetSprite(string key)
        {
            if (_cache.TryGetValue(key, out var sprite) && sprite != null)
                return sprite;

            sprite = GenerateSprite(key);
            if (sprite != null)
                _cache[key] = sprite;

            return sprite;
        }

        private static Sprite GenerateSprite(string key)
        {
            switch (key)
            {
                case "player":
                    return CreatePlayerSprite();
                case "sword":
                    return CreateSwordSprite();
                case "chaser":
                case "ranger":
                case "brute":
                case "boss":
                    return EnemySpriteBytes.Create(key, 48f, new Vector2(0.5f, 0.18f))
                           ?? GenerateFallbackEnemy(key);
                case "bomber":
                    return CreateBomberSprite();
                case "projectile_player":
                    return CreateCircle(32, new Color(0.2f, 0.9f, 1f), Color.white, 2);
                case "projectile_enemy":
                    return CreateCircle(32, new Color(1f, 0.25f, 0.25f), new Color(1f, 0.8f, 0.4f), 2);
                case "gem_xp":
                    return CreateDiamond(32, new Color(0.15f, 0.85f, 1f), Color.white, 2);
                case "coin":
                    return CreateCoinSprite();
                case "potion_hp":
                    return CreatePotionSprite();
                case "chest":
                    return CreateChestSprite();
                case "portal":
                    return CreatePortalSprite();
                case "floor_tile":
                    return CreateFloorTileSprite();
                case "wall_tile":
                    return CreateWallTileSprite();
                case "pillar":
                    return CreatePillarSprite();
                case "slash":
                    return CreateSlashSprite();
                case "ui_bar":
                    return CreateRoundedRect(64, 16, 4, Color.white, Color.clear, 0);
                default:
                    return CreateCircle(32, Color.white, Color.gray, 2);
            }
        }

        public static Sprite CreatePlayerSprite()
        {
            // Chibi anime girl in a cyan bikini — 3/4 view, pixel art.
            const int w = 80;
            const int h = 96;
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.filterMode = FilterMode.Point;
            tex.wrapMode = TextureWrapMode.Clamp;
            var px = new Color32[w * h];

            Color32 Col(byte r, byte g, byte b) => new Color32(r, g, b, 255);
            var outline = Col(28, 16, 32);
            var hair = Col(42, 16, 48);
            var hairMid = Col(92, 32, 96);
            var hairLight = Col(186, 78, 168);
            var hairShine = Col(240, 170, 220);
            var skin = Col(255, 214, 186);
            var skinShadow = Col(232, 168, 148);
            var blush = Col(255, 150, 160);
            var eyeWhite = Col(250, 252, 255);
            var iris = Col(40, 150, 210);
            var irisDark = Col(18, 50, 110);
            var bikini = Col(36, 210, 240);
            var bikiniDark = Col(18, 130, 170);
            var bikiniWhite = Col(250, 252, 255);
            var lip = Col(220, 90, 110);

            void Plot(int x, int y, Color32 c)
            {
                if ((uint)x >= (uint)w || (uint)y >= (uint)h) return;
                px[y * w + x] = c;
            }

            void FillCircle(float cx, float cy, float r, Color32 c)
            {
                int x0 = Mathf.Max(0, Mathf.FloorToInt(cx - r));
                int x1 = Mathf.Min(w - 1, Mathf.CeilToInt(cx + r));
                int y0 = Mathf.Max(0, Mathf.FloorToInt(cy - r));
                int y1 = Mathf.Min(h - 1, Mathf.CeilToInt(cy + r));
                float r2 = r * r;
                for (int y = y0; y <= y1; y++)
                {
                    for (int x = x0; x <= x1; x++)
                    {
                        float dx = x - cx;
                        float dy = y - cy;
                        if (dx * dx + dy * dy <= r2) Plot(x, y, c);
                    }
                }
            }

            void FillEllipse(float cx, float cy, float rx, float ry, Color32 c)
            {
                int x0 = Mathf.Max(0, Mathf.FloorToInt(cx - rx));
                int x1 = Mathf.Min(w - 1, Mathf.CeilToInt(cx + rx));
                int y0 = Mathf.Max(0, Mathf.FloorToInt(cy - ry));
                int y1 = Mathf.Min(h - 1, Mathf.CeilToInt(cy + ry));
                for (int y = y0; y <= y1; y++)
                {
                    for (int x = x0; x <= x1; x++)
                    {
                        float nx = (x - cx) / rx;
                        float ny = (y - cy) / ry;
                        if (nx * nx + ny * ny <= 1f) Plot(x, y, c);
                    }
                }
            }

            void FillRect(int x0, int y0, int x1, int y1, Color32 c)
            {
                x0 = Mathf.Clamp(x0, 0, w - 1);
                x1 = Mathf.Clamp(x1, 0, w - 1);
                y0 = Mathf.Clamp(y0, 0, h - 1);
                y1 = Mathf.Clamp(y1, 0, h - 1);
                for (int y = y0; y <= y1; y++)
                    for (int x = x0; x <= x1; x++)
                        Plot(x, y, c);
            }

            void DrawEye(float ex, float ey, bool lookLeft)
            {
                FillEllipse(ex, ey, 5.4f, 6.2f, eyeWhite);
                float ix = lookLeft ? ex - 0.8f : ex + 0.4f;
                FillCircle(ix, ey - 0.4f, 3.3f, iris);
                FillCircle(ix, ey - 0.8f, 2.0f, irisDark);
                FillCircle(ix - 1.4f, ey + 1.6f, 1.5f, eyeWhite);
                FillCircle(ix + 1.1f, ey - 1.8f, 0.9f, eyeWhite);
                FillEllipse(ex, ey + 5.4f, 5.6f, 1.6f, hair); // lash / lid
            }

            float cx = (w - 1) * 0.5f;

            // Hair behind (long twin tails)
            FillEllipse(cx, 58, 20, 24, hair);
            FillEllipse(cx - 18, 36, 9, 22, hair);
            FillEllipse(cx + 19, 34, 9, 24, hair);
            FillEllipse(cx - 20, 18, 7, 14, hairMid);
            FillEllipse(cx + 21, 16, 7, 16, hairMid);
            FillEllipse(cx - 18, 44, 4, 8, hairLight);
            FillEllipse(cx + 18, 42, 4, 8, hairLight);

            // Legs
            FillEllipse(cx - 7, 18, 5.2f, 12, skinShadow);
            FillEllipse(cx + 8, 18, 5.2f, 12, skin);
            FillEllipse(cx - 7, 8, 4.6f, 3.4f, skin);   // feet
            FillEllipse(cx + 9, 8, 4.6f, 3.4f, skin);

            // Hips + bikini bottom
            FillEllipse(cx, 30, 12, 9, skin);
            FillEllipse(cx, 29, 11, 6.5f, bikini);
            FillEllipse(cx, 27.5f, 9, 3.2f, bikiniDark);
            FillRect((int)cx - 1, 28, (int)cx + 1, 34, bikiniWhite); // center tie
            FillEllipse(cx - 6, 31, 2.2f, 1.6f, bikiniWhite);
            FillEllipse(cx + 6, 31, 2.2f, 1.6f, bikiniWhite);

            // Torso
            FillEllipse(cx, 42, 9.5f, 12, skin);
            FillEllipse(cx - 1, 46, 6, 7, skin);
            FillRect((int)cx - 3, 36, (int)cx + 3, 48, skin);

            // Bikini top
            FillCircle(cx - 6.2f, 48, 5.2f, bikini);
            FillCircle(cx + 6.2f, 48, 5.2f, bikini);
            FillCircle(cx - 6.2f, 48, 3.4f, bikiniDark);
            FillCircle(cx + 6.2f, 48, 3.4f, bikiniDark);
            FillCircle(cx - 7.2f, 49.5f, 1.6f, bikiniWhite);
            FillCircle(cx + 5.2f, 49.5f, 1.6f, bikiniWhite);
            FillRect((int)cx - 2, 48, (int)cx + 2, 50, bikiniWhite); // bridge
            FillEllipse(cx, 53.5f, 8, 1.3f, bikiniWhite); // neck strap

            // Arms
            FillEllipse(cx - 14, 40, 3.4f, 10, skinShadow);
            FillEllipse(cx + 14, 40, 3.4f, 10, skin);
            FillCircle(cx - 14, 30, 3.2f, skin); // hands
            FillCircle(cx + 15, 30, 3.2f, skin);

            // Neck + head
            FillRect((int)cx - 3, 54, (int)cx + 3, 60, skin);
            FillCircle(cx, 70, 16.5f, skin);
            FillEllipse(cx, 66, 15, 14, skin);
            FillEllipse(cx - 4, 64, 5, 4, blush); // cheek
            FillEllipse(cx + 7, 64, 4.5f, 3.5f, blush);

            // Face
            DrawEye(cx - 6.0f, 70, true);
            DrawEye(cx + 7.0f, 70, true);
            FillEllipse(cx + 1, 62.5f, 2.2f, 1.1f, lip); // mouth
            FillEllipse(cx + 1, 63.2f, 1.4f, 0.6f, skin); // slight open look
            FillCircle(cx + 8, 76, 1.6f, Col(255, 250, 252)); // nose highlight

            // Bangs + top hair
            FillEllipse(cx, 82, 16, 8, hair);
            FillEllipse(cx - 10, 78, 8, 10, hair);
            FillEllipse(cx + 10, 78, 8, 10, hair);
            FillEllipse(cx - 2, 84, 6, 5, hairMid);
            FillEllipse(cx - 8, 80, 3.5f, 7, hairLight);
            FillEllipse(cx + 6, 81, 3.2f, 5, hairShine);
            // Side bangs over cheeks
            FillEllipse(cx - 14, 68, 4.5f, 10, hair);
            FillEllipse(cx + 15, 67, 4.5f, 11, hair);

            // Hair bow
            FillCircle(cx + 12, 86, 3.4f, bikini);
            FillEllipse(cx + 8, 86, 4.5f, 3.2f, bikini);
            FillEllipse(cx + 16, 86, 4.5f, 3.2f, bikini);
            FillCircle(cx + 12, 86, 1.6f, bikiniWhite);

            // Cartoon outline around opaque pixels
            var src = (Color32[])px.Clone();
            int[] ox = { -1, 0, 1, -1, 1, -1, 0, 1 };
            int[] oy = { -1, -1, -1, 0, 0, 1, 1, 1 };
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    if (src[y * w + x].a != 0) continue;
                    bool neighbor = false;
                    for (int i = 0; i < 8; i++)
                    {
                        int nx = x + ox[i];
                        int ny = y + oy[i];
                        if ((uint)nx >= (uint)w || (uint)ny >= (uint)h) continue;
                        if (src[ny * w + nx].a != 0) { neighbor = true; break; }
                    }
                    if (neighbor) Plot(x, y, outline);
                }
            }

            tex.SetPixels32(px);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.20f), 48);
        }

        public static Sprite CreateSwordSprite()
        {
            int w = 24, h = 64;
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.filterMode = FilterMode.Point;
            var colors = new Color32[w * h];

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    Color32 col = Color.clear;
                    int mid = w / 2;
                    int dx = Mathf.Abs(x - mid);

                    // Blade
                    if (y >= 16 && y < h - 4)
                    {
                        int halfBladeWidth = y > h - 10 ? (h - y) / 2 : 4;
                        if (dx <= halfBladeWidth)
                        {
                            col = (dx == 0) ? new Color32(255, 255, 255, 255) : new Color32(200, 225, 255, 255);
                        }
                    }
                    // Crossguard
                    else if (y >= 12 && y < 16)
                    {
                        if (dx <= 9)
                            col = new Color32(255, 205, 50, 255);
                    }
                    // Handle & Pommel
                    else if (y >= 2 && y < 12)
                    {
                        if (dx <= 2)
                            col = new Color32(110, 65, 40, 255);
                        if (y <= 4 && dx <= 3)
                            col = new Color32(255, 205, 50, 255);
                    }

                    colors[y * w + x] = col;
                }
            }

            tex.SetPixels32(colors);
            tex.Apply();
            // Pivot at handle
            return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.2f), 32);
        }

        /// <summary>Sprite pixel-art cho Bomber Slime: thân cam đổ bóng, mắt giận, ngòi có tia lửa.</summary>
        public static Sprite CreateBomberSprite()
        {
            const int w = 48, h = 56;
            var px = new Color32[w * h];

            Color32 outline = new Color32(92, 28, 12, 255);
            Color32 dark = new Color32(214, 96, 24, 255);
            Color32 mid = new Color32(255, 140, 38, 255);
            Color32 light = new Color32(255, 196, 96, 255);
            Color32 white = new Color32(255, 255, 255, 255);
            Color32 pupil = new Color32(40, 12, 8, 255);
            Color32 fuse = new Color32(110, 70, 40, 255);
            Color32 spark = new Color32(255, 235, 90, 255);

            void Put(int x, int y, Color32 c)
            {
                if (x < 0 || y < 0 || x >= w || y >= h) return;
                px[y * w + x] = c;
            }

            // Thân tròn hơi bẹt, tâm (24, 24)
            const float cx = 23.5f, cy = 24f, rx = 21f, ry = 19f;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    float nx = (x - cx) / rx;
                    float ny = (y - cy) / ry;
                    float d = nx * nx + ny * ny;
                    if (d > 1f) continue;

                    // Viền: lớp ngoài cùng
                    float inner = ((x - cx) / (rx - 2.2f)) * ((x - cx) / (rx - 2.2f)) + ((y - cy) / (ry - 2.2f)) * ((y - cy) / (ry - 2.2f));
                    if (inner > 1f) { Put(x, y, outline); continue; }

                    // Đổ bóng: sáng ở trên-trái, tối ở dưới-phải (chia 3 mức cho đúng kiểu pixel art)
                    float shade = -nx * 0.55f + ny * 0.8f; // y tăng lên trên nên ny lớn = phía trên
                    Put(x, y, shade > 0.35f ? light : (shade > -0.25f ? mid : dark));
                }
            }

            // Vệt sáng nhỏ
            Put(8, 30, white); Put(8, 31, white); Put(8, 32, white); Put(9, 33, white);

            // Mắt giận dữ
            void Eye(int ex, int ey)
            {
                for (int y = -4; y <= 4; y++)
                    for (int x = -3; x <= 3; x++)
                        if ((x * x) / 9f + (y * y) / 16f <= 1f) Put(ex + x, ey + y, white);
                // Đồng tử nhìn xuống-giữa
                for (int y = -2; y <= 1; y++)
                    for (int x = -1; x <= 1; x++)
                        Put(ex + x, ey + y - 1, pupil);
            }
            Eye(16, 27);
            Eye(31, 27);

            // Lông mày nhíu: dốc vào trong
            for (int i = 0; i < 6; i++)
            {
                Put(12 + i, 34 - i / 2, outline);
                Put(12 + i, 33 - i / 2, outline);
                Put(35 - i, 34 - i / 2, outline);
                Put(35 - i, 33 - i / 2, outline);
            }

            // Miệng nhe răng nhỏ
            for (int x = 18; x <= 29; x++) Put(x, 15, outline);
            for (int x = 19; x <= 28; x += 3) { Put(x, 14, white); Put(x + 1, 14, white); }

            // Ngòi: đi lên từ đỉnh thân
            int fx = 24, fy = 42;
            for (int i = 0; i < 6; i++)
            {
                Put(fx + i / 2, fy + i, fuse);
                Put(fx + 1 + i / 2, fy + i, fuse);
            }
            // Tia lửa ở đầu ngòi
            int sx = fx + 3, sy = fy + 7;
            Put(sx, sy, white);
            Put(sx - 1, sy, spark); Put(sx + 1, sy, spark); Put(sx, sy - 1, spark); Put(sx, sy + 1, spark);
            Put(sx - 2, sy + 1, spark); Put(sx + 2, sy + 1, spark); Put(sx, sy + 2, spark);
            Put(sx - 2, sy - 2, new Color32(255, 160, 30, 255)); Put(sx + 2, sy - 2, new Color32(255, 160, 30, 255));

            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.filterMode = FilterMode.Point;
            tex.SetPixels32(px);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.18f), 40f);
        }

        public static Sprite CreateChaserSprite()
        {
            return EnemySpriteBytes.Create("chaser", 48f, new Vector2(0.5f, 0.18f))
                   ?? GenerateFallbackEnemy("chaser");
        }

        public static Sprite CreateRangerSprite()
        {
            return EnemySpriteBytes.Create("ranger", 48f, new Vector2(0.5f, 0.18f))
                   ?? GenerateFallbackEnemy("ranger");
        }

        public static Sprite CreateBruteSprite()
        {
            return EnemySpriteBytes.Create("brute", 48f, new Vector2(0.5f, 0.18f))
                   ?? GenerateFallbackEnemy("brute");
        }

        public static Sprite CreateBossSprite()
        {
            return EnemySpriteBytes.Create("boss", 48f, new Vector2(0.5f, 0.18f))
                   ?? GenerateFallbackEnemy("boss");
        }

        private static Sprite GenerateFallbackEnemy(string key)
        {
            switch (key)
            {
                case "ranger":
                    return CreateCircle(48, new Color(0.90f, 0.22f, 0.28f), new Color(0.35f, 0.08f, 0.12f), 3);
                case "brute":
                    return CreateCircle(64, new Color(0.45f, 0.28f, 0.82f), new Color(0.18f, 0.10f, 0.32f), 4);
                case "boss":
                    return CreateCircle(88, new Color(0.72f, 0.12f, 0.18f), new Color(0.90f, 0.75f, 0.25f), 5);
                default:
                    return CreateCircle(48, new Color(0.35f, 0.88f, 0.32f), new Color(0.10f, 0.28f, 0.12f), 3);
            }
        }

        public static Sprite CreateCoinSprite()
        {
            int size = 32;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.42f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), c);
                    if (d <= r)
                    {
                        if (d >= r - 2.5f || d <= r * 0.45f)
                            colors[y * size + x] = new Color32(255, 235, 120, 255);
                        else
                            colors[y * size + x] = new Color32(245, 185, 20, 255);
                    }
                    else
                        colors[y * size + x] = Color.clear;
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreatePotionSprite()
        {
            int size = 36;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, 14f);

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float dx = Mathf.Abs(x - c.x);
                    Color32 col = Color.clear;

                    // Round flask bottom
                    float d = Vector2.Distance(new Vector2(x, y), c);
                    if (d <= 12f)
                    {
                        col = (d >= 10f) ? new Color32(255, 255, 255, 255) : new Color32(235, 45, 75, 255);
                    }
                    // Flask neck
                    else if (y >= 20 && y <= 28 && dx <= 4)
                    {
                        col = (dx >= 3) ? new Color32(255, 255, 255, 255) : new Color32(210, 230, 255, 200);
                    }
                    // Cork
                    else if (y > 28 && y <= 33 && dx <= 5)
                    {
                        col = new Color32(180, 110, 60, 255);
                    }

                    colors[y * size + x] = col;
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateChestSprite()
        {
            int size = 48;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    Color32 col = Color.clear;
                    if (x >= 6 && x < size - 6 && y >= 6 && y < size - 10)
                    {
                        bool border = (x <= 8 || x >= size - 9 || y <= 8 || y >= size - 12);
                        bool lockPlate = (Mathf.Abs(x - size / 2) <= 3 && Mathf.Abs(y - size / 2) <= 3);

                        if (border || lockPlate)
                            col = new Color32(255, 210, 50, 255); // Gold trim & lock
                        else if (y == 24)
                            col = new Color32(40, 25, 15, 255); // Seam
                        else
                            col = new Color32(140, 75, 35, 255); // Wood body
                    }
                    colors[y * size + x] = col;
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreatePortalSprite()
        {
            int size = 64;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.45f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), c);
                    if (d <= r)
                    {
                        float t = d / r;
                        if (t > 0.8f)
                            colors[y * size + x] = new Color32(100, 240, 255, 255); // Outer glow
                        else if (t > 0.5f)
                            colors[y * size + x] = new Color32(50, 150, 255, 220); // Mid ring
                        else
                            colors[y * size + x] = new Color32(20, 40, 90, 255);  // Void center
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateFloorTileSprite()
        {
            int size = 64;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    bool border = (x == 0 || x == size - 1 || y == 0 || y == size - 1);
                    if (border)
                    {
                        colors[y * size + x] = new Color32(32, 36, 48, 255);
                    }
                    else
                    {
                        // Subtle slate stone texture
                        byte v = (byte)(46 + ((x ^ y) % 5));
                        colors[y * size + x] = new Color32(v, (byte)(v + 4), (byte)(v + 10), 255);
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateWallTileSprite()
        {
            int size = 64;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    bool border = (x == 0 || x == size - 1 || y == 0 || y == size - 1 || y == size / 2);
                    if (border)
                        colors[y * size + x] = new Color32(18, 20, 28, 255);
                    else
                        colors[y * size + x] = new Color32(75, 82, 100, 255);
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreatePillarSprite()
        {
            int size = 64;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.44f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), c);
                    if (d <= r)
                    {
                        if (d >= r - 3)
                            colors[y * size + x] = new Color32(30, 35, 45, 255);
                        else if (d <= r * 0.4f)
                            colors[y * size + x] = new Color32(100, 220, 255, 255); // Glowing rune core
                        else
                            colors[y * size + x] = new Color32(95, 105, 125, 255);
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateSlashSprite()
        {
            int size = 64;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2(8f, (size - 1) / 2f);

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), c);
                    float angle = Mathf.Atan2(y - c.y, x - c.x) * Mathf.Rad2Deg;

                    if (d >= 24f && d <= 36f && angle >= -45f && angle <= 45f)
                    {
                        float alpha = 1f - (Mathf.Abs(angle) / 45f);
                        colors[y * size + x] = new Color(1f, 1f, 1f, alpha * 0.85f);
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.2f, 0.5f), 32);
        }

        public static Sprite CreateCircle(int size, Color fill, Color outline, int outlineWidth)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.46f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), c);
                    if (d <= r)
                    {
                        if (outlineWidth > 0 && d >= r - outlineWidth)
                            colors[y * size + x] = outline;
                        else
                            colors[y * size + x] = fill;
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateDiamond(int size, Color fill, Color outline, int outlineWidth)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.46f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float d = (Mathf.Abs(x - c.x) + Mathf.Abs(y - c.y));
                    if (d <= r)
                    {
                        if (outlineWidth > 0 && d >= r - outlineWidth)
                            colors[y * size + x] = outline;
                        else
                            colors[y * size + x] = fill;
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateHexagon(int size, Color fill, Color outline, int outlineWidth)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.46f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float dx = Mathf.Abs(x - c.x) / r;
                    float dy = Mathf.Abs(y - c.y) / r;
                    // Hexagon inequality
                    float d = Mathf.Max(dx * 0.866025f + dy * 0.5f, dy);
                    if (d <= 0.866025f)
                    {
                        if (outlineWidth > 0 && d >= 0.866025f - (outlineWidth / (float)size))
                            colors[y * size + x] = outline;
                        else
                            colors[y * size + x] = fill;
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateOctagon(int size, Color fill, Color outline, int outlineWidth)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colors = new Color32[size * size];
            Vector2 c = new Vector2((size - 1) / 2f, (size - 1) / 2f);
            float r = size * 0.46f;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float dx = Mathf.Abs(x - c.x);
                    float dy = Mathf.Abs(y - c.y);
                    float d = Mathf.Max(Mathf.Max(dx, dy), (dx + dy) * 0.7071f);
                    if (d <= r)
                    {
                        if (outlineWidth > 0 && d >= r - outlineWidth)
                            colors[y * size + x] = outline;
                        else
                            colors[y * size + x] = fill;
                    }
                    else
                    {
                        colors[y * size + x] = Color.clear;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 32);
        }

        public static Sprite CreateRoundedRect(int width, int height, int radius, Color fill, Color outline, int outlineWidth)
        {
            var tex = new Texture2D(width, height, TextureFormat.RGBA32, false);
            var colors = new Color32[width * height];

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int cornerX = (x < radius) ? radius - x : (x >= width - radius) ? x - (width - radius - 1) : 0;
                    int cornerY = (y < radius) ? radius - y : (y >= height - radius) ? y - (height - radius - 1) : 0;

                    if (cornerX > 0 && cornerY > 0 && (cornerX * cornerX + cornerY * cornerY) > radius * radius)
                    {
                        colors[y * width + x] = Color.clear;
                    }
                    else
                    {
                        if (outlineWidth > 0 && (x < outlineWidth || x >= width - outlineWidth || y < outlineWidth || y >= height - outlineWidth))
                            colors[y * width + x] = outline;
                        else
                            colors[y * width + x] = fill;
                    }
                }
            }
            tex.SetPixels32(colors);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, width, height), new Vector2(0.5f, 0.5f), 32);
        }
    }
}
