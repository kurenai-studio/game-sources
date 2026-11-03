using System.Collections.Generic;
using UnityEngine;

namespace PixelLeap.Core
{
    /// <summary>
    /// 运行时生成纯色方块 / 三角形 Sprite，让项目不依赖任何美术资源即可运行（原型阶段常用做法）。
    /// </summary>
    public static class SpriteFactory
    {
        static readonly Dictionary<string, Sprite> cache = new Dictionary<string, Sprite>();

        public static Sprite Square() => Get("square", (x, y, n) => true);

        public static Sprite Triangle() => Get("triangle", (x, y, n) =>
            Mathf.Abs(x - (n - 1) * 0.5f) <= (n - y) * 0.5f);

        public static Sprite Circle() => Get("circle", (x, y, n) =>
        {
            float c = (n - 1) * 0.5f;
            return (x - c) * (x - c) + (y - c) * (y - c) <= c * c + 0.5f;
        });

        static Sprite Get(string key, System.Func<int, int, int, bool> inside)
        {
            if (cache.TryGetValue(key, out var s) && s) return s;
            const int n = 16;
            var tex = new Texture2D(n, n, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp,
                hideFlags = HideFlags.DontSave
            };
            var pixels = new Color32[n * n];
            for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++)
                pixels[y * n + x] = inside(x, y, n) ? new Color32(255, 255, 255, 255) : new Color32(0, 0, 0, 0);
            tex.SetPixels32(pixels);
            tex.Apply();
            s = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), n, 0, SpriteMeshType.FullRect);  // FullRect 才能用 Tiled 绘制
            s.hideFlags = HideFlags.DontSave;
            cache[key] = s;
            return s;
        }

        /// <summary>创建一个带纯色 SpriteRenderer 的子物体，常用于快速搭建原型。</summary>
        public static SpriteRenderer AddVisual(GameObject go, Sprite sprite, Color color, int order = 0)
        {
            var sr = go.GetComponent<SpriteRenderer>();
            if (!sr) sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = sprite;
            sr.color = color;
            sr.sortingOrder = order;
            return sr;
        }
    }
}
