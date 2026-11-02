using System;
using Microsoft.Xna.Framework;

namespace Breakout.Systems;

/// <summary>
/// Trauma-style screen shake (squared falloff, after Jonasson's "Juice it or
/// lose it"): impacts add trauma, displayed intensity is trauma², trauma decays
/// linearly. Small hits barely register, big hits kick — and it composes when
/// several impacts land close together.
/// Implemented as a translation matrix handed to SpriteBatch.Begin: the whole
/// world is drawn shifted while the world data itself never moves.
/// </summary>
public sealed class ScreenShake
{
    private const float MaxOffset = 8f;
    private const float DecayPerSecond = 1.6f;

    private readonly Random _rng;
    private float _trauma;
    private Vector2 _offset;

    public ScreenShake(Random rng) => _rng = rng;

    /// <param name="amount">0..1; stacks, capped at 1.</param>
    public void Add(float amount) => _trauma = MathF.Min(1f, _trauma + amount);

    public void Update(float dt)
    {
        _trauma = MathF.Max(0f, _trauma - DecayPerSecond * dt);

        // The random roll happens here, once per tick — not in the property
        // below. A getter that returns a different value every read is a trap:
        // read it twice in one frame and the two consumers disagree.
        if (_trauma <= 0f)
        {
            _offset = Vector2.Zero;
            return;
        }

        float magnitude = _trauma * _trauma * MaxOffset;
        _offset = new Vector2(
            ((float)_rng.NextDouble() * 2f - 1f) * magnitude,
            ((float)_rng.NextDouble() * 2f - 1f) * magnitude);
    }

    public Matrix TransformMatrix => Matrix.CreateTranslation(_offset.X, _offset.Y, 0f);
}
