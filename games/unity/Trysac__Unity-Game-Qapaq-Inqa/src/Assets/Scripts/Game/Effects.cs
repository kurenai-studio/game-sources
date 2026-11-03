using System.Collections.Generic;
using UnityEngine;

namespace QapaqInqa.Game
{
    /// <summary>
    /// Tiny square particles drawn with pooled sprites: dust, sparkles, rubble and embers.
    /// They run on unscaled time so hit-stop freezes the action but not the burst.
    /// </summary>
    public sealed class Effects : MonoBehaviour
    {
        sealed class Particle
        {
            public SpriteRenderer Renderer;
            public Vector2 Velocity;
            public float Gravity;
            public float Life;
            public float Age;
            public float Size;
            public Color Color;
        }

        readonly List<Particle> live = new List<Particle>();
        readonly Stack<SpriteRenderer> spare = new Stack<SpriteRenderer>();
        Sprite square;

        public int Count => live.Count;

        void Awake()
        {
            var texture = new Texture2D(2, 2, TextureFormat.RGBA32, false) { filterMode = FilterMode.Point };
            Color32 white = Color.white;
            texture.SetPixels32(new[] { white, white, white, white });
            texture.Apply();
            square = Sprite.Create(texture, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 16f);
        }

        public void Burst(Vector2 at, Color color, int count, float speed, float gravity = 20f, float life = 0.5f, float size = 1f, Vector2 bias = default)
        {
            for (int i = 0; i < count; i++)
            {
                float angle = Random.Range(0f, Mathf.PI * 2f);
                float s = Random.Range(0.3f, 1f) * speed;
                Spawn(at, new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * s + bias, color, gravity, life * Random.Range(0.6f, 1.2f), size);
            }
        }

        public void Dust(Vector2 feet, int count = 6) =>
            Burst(feet + new Vector2(0f, 0.05f), new Color(0.85f, 0.78f, 0.62f, 0.9f), count, 2.5f, 4f, 0.35f, 1f, new Vector2(0f, 0.8f));

        public void Sparkle(Vector2 at, Color color) => Burst(at, color, 10, 4f, 2f, 0.5f, 0.8f);

        public void Rubble(Vector2 at, Color color) => Burst(at, color, 16, 6f, 25f, 0.8f, 1.6f, new Vector2(0f, 3f));

        public void Clear()
        {
            foreach (Particle p in live) Recycle(p.Renderer);
            live.Clear();
        }

        void Spawn(Vector2 at, Vector2 velocity, Color color, float gravity, float life, float size)
        {
            SpriteRenderer renderer = spare.Count > 0 ? spare.Pop() : Create();
            renderer.gameObject.SetActive(true);
            renderer.color = color;
            renderer.transform.position = new Vector3(at.x, at.y, -1f);
            renderer.transform.localScale = Vector3.one * size;
            live.Add(new Particle { Renderer = renderer, Velocity = velocity, Gravity = gravity, Life = life, Size = size, Color = color });
        }

        SpriteRenderer Create()
        {
            var go = new GameObject("Particle");
            go.transform.SetParent(transform, false);
            var renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = square;
            renderer.sortingOrder = 8;
            return renderer;
        }

        void Recycle(SpriteRenderer renderer)
        {
            renderer.gameObject.SetActive(false);
            spare.Push(renderer);
        }

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            for (int i = live.Count - 1; i >= 0; i--)
            {
                Particle p = live[i];
                p.Age += dt;
                if (p.Age >= p.Life)
                {
                    Recycle(p.Renderer);
                    live.RemoveAt(i);
                    continue;
                }
                p.Velocity += new Vector2(0f, -p.Gravity * dt);
                p.Renderer.transform.position += (Vector3)(p.Velocity * dt);
                float t = p.Age / p.Life;
                Color c = p.Color;
                c.a *= 1f - t * t;
                p.Renderer.color = c;
                p.Renderer.transform.localScale = Vector3.one * p.Size * (1f - t * 0.5f);
            }
        }
    }
}
