using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.Entities;

public enum PowerUpType
{
    WidePaddle,
    Multiball,
    Debris, // the anti-power-up: catching it *hurts* (shrinks the paddle)
}

/// <summary>
/// A falling pickup dropped by a destroyed brick. It only knows how to fall
/// and pulse; PlayingState detects the catch and applies the actual effect,
/// so adding a new power-up means a new enum member and one switch arm there.
/// Debris proved that promise also holds when the effect is *negative*: the
/// spawn/fall/catch pipeline never knew it was carrying prizes, so a hazard
/// is just one more enum member — only the meaning (and the look) flips.
/// </summary>
public class PowerUp
{
    public const float WidePaddleDuration = 10f;
    public const float DebrisShrinkDuration = 8f;

    private const int Width = 26;
    private const int Height = 14;
    private const float FallSpeed = 130f;
    private const float DebrisFallSpeed = 175f; // harder to dodge than to catch

    /// <summary>Catching this is bad — the player should dodge, not chase.</summary>
    public bool IsHazard => Type == PowerUpType.Debris;

    public PowerUpType Type { get; }
    public Vector2 Position; // center

    private float _age;

    public PowerUp(PowerUpType type, Vector2 position)
    {
        Type = type;
        Position = position;
    }

    // Hazards get the *smaller* box of their visual, never the prize's wide
    // one — a hitbox bigger than the drawing punishes a dodge that looked
    // clean, and unfair-feeling collision is the fastest way to lose a player.
    public Rectangle Bounds => IsHazard
        ? new Rectangle((int)(Position.X - 7), (int)(Position.Y - 7), 14, 14)
        : new Rectangle(
            (int)(Position.X - Width / 2f), (int)(Position.Y - Height / 2f), Width, Height);

    public bool IsBelowScreen => Position.Y - Height / 2f > Screen.Height;

    public void Update(float dt)
    {
        Position.Y += (IsHazard ? DebrisFallSpeed : FallSpeed) * dt;
        _age += dt;
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        if (IsHazard)
        {
            DrawDebris(spriteBatch);
            return;
        }

        // With no sprites, color *is* the identity: pink ring = wide paddle,
        // cyan ring = multiball. Players learn a color code in one catch.
        Color ring = Type == PowerUpType.WidePaddle
            ? new Color(255, 80, 200)
            : new Color(80, 200, 255);

        // Pulse so it reads as "catch me", not as a falling brick.
        int pulse = (int)(MathF.Sin(_age * 8f) * 2f);
        Rectangle b = Bounds;
        b.Inflate(pulse, pulse / 2);
        spriteBatch.DrawRect(b, ring);
        b.Inflate(-3, -3);
        spriteBatch.DrawRect(b, Color.White);
    }

    private void DrawDebris(SpriteBatch spriteBatch)
    {
        // Good-vs-harm readability with one texture and no rotation support:
        // invert every cue the prizes established. Prizes are wide, bright-
        // centered, and pulse outward ("catch me"); debris is squarish,
        // *dark*-centered with an ember edge, and its width and height
        // counter-oscillate — the silhouette an axis-aligned box traces when
        // a square tumbles — which reads as falling rubble, not a pickup.
        int wobble = (int)(MathF.Sin(_age * 9f) * 4f);
        var b = new Rectangle(
            (int)Position.X - (14 + wobble) / 2,
            (int)Position.Y - (14 - wobble) / 2,
            14 + wobble, 14 - wobble);
        spriteBatch.DrawRect(b, new Color(200, 70, 40));
        b.Inflate(-3, -3);
        spriteBatch.DrawRect(b, new Color(58, 54, 62));
    }
}
