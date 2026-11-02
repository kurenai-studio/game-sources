using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Breakout.Systems;

/// <summary>
/// Minimal burst-particle system: squares that fly out, fall under gravity,
/// shrink and fade. Particles are structs so updating hundreds of them
/// allocates nothing — note the read-modify-write-back in Update; a List
/// indexer returns a *copy* of a struct, so mutating it in place is impossible.
/// </summary>
public sealed class ParticleSystem
{
    private struct Particle
    {
        public Vector2 Position, Velocity;
        public float Age, Lifetime, Size;
        public Color Color;
    }

    private const float Gravity = 520f;

    private readonly List<Particle> _particles = new();

    public int Count => _particles.Count;

    public void Emit(Vector2 origin, Color color, int count, Random rng)
    {
        for (int i = 0; i < count; i++)
        {
            float angle = (float)(rng.NextDouble() * Math.PI * 2);
            float speed = 40f + (float)rng.NextDouble() * 200f;
            _particles.Add(new Particle
            {
                Position = origin,
                Velocity = new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * speed,
                Lifetime = 0.3f + (float)rng.NextDouble() * 0.5f,
                Size = 2f + (float)rng.NextDouble() * 3f,
                Color = color,
            });
        }
    }

    public void Update(float dt)
    {
        for (int i = 0; i < _particles.Count; i++)
        {
            Particle p = _particles[i];
            p.Velocity.Y += Gravity * dt;
            p.Position += p.Velocity * dt;
            p.Age += dt;
            _particles[i] = p;
        }
        _particles.RemoveAll(p => p.Age >= p.Lifetime);
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        foreach (Particle p in _particles)
        {
            float life = 1f - p.Age / p.Lifetime;
            int size = Math.Max(1, (int)(p.Size * life));
            var rect = new Rectangle(
                (int)p.Position.X - size / 2, (int)p.Position.Y - size / 2, size, size);
            // `Color * float` premultiplies RGB and A together — the correct way
            // to fade under SpriteBatch's default premultiplied alpha blending.
            spriteBatch.DrawRect(rect, p.Color * life);
        }
    }
}
