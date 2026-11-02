using System;
using Microsoft.Xna.Framework;

namespace Breakout.Systems;

/// <summary>
/// The 1978 Super Breakout numbers, gathered in one place like ClassicRules —
/// sourced from Atari's operation manual (TM-118). What the sequel changed:
///
///  - Five ball speeds instead of four. Speed-ups on the 4th, 8th and 12th
///    paddle return, and the ball jumps straight to top speed the moment any
///    high-point (5 or 7) brick is destroyed.
///  - The pass-through rule replaces 1976's one-brick-per-trip: a ball the
///    paddle has not yet returned passes through bricks untouched, and after
///    every destroyed brick the ball keeps passing through ("boring") until
///    it has travelled four rows or touched the paddle or the top boundary.
///  - The half-width penalty now triggers on top-boundary contact and lasts
///    only "until the next serve".
///  - Brick scores multiply by the number of balls in the playfield — the
///    sequel's whole premise is more than one ball.
///
/// Same reconstructions as ClassicRules, same reason: the manual's rebound
/// figure is a diagram with no angles, and "hit" is never defined. Here we
/// count paddle returns (the manual ties the rebound-angle changes to the
/// same 4/8/12 counter, and rebounds happen at the paddle), where the 1976
/// state counts destroyed bricks — both readings are defensible.
/// </summary>
public static class SuperRules
{
    /// <summary>Pixels per second for speed levels 0-4.</summary>
    public static readonly float[] Speeds = { 280f, 340f, 400f, 470f, 560f };

    public const int FirstSpeedUpHits = 4;
    public const int SecondSpeedUpHits = 8;
    public const int ThirdSpeedUpHits = 12;

    /// <summary>5- and 7-point bricks force the top speed instantly.</summary>
    public const int HighBrickScore = 5;

    /// <summary>How far a ball bores after destroying a brick before it may
    /// destroy another (manual: "at least four rows from the last brick hit").</summary>
    public const int BoreRows = 4;

    // Rebound angles in degrees from vertical, per speed level — the inner
    // half of the paddle sends the ball steep, the outer half sends it wide,
    // and the manual is explicit that "the angles of rebound become more
    // perpendicular as ball speed increases" (reconstructed values).
    private static readonly float[] InnerAngles = { 32f, 29f, 26f, 23f, 20f };
    private static readonly float[] OuterAngles = { 58f, 53f, 48f, 44f, 40f };

    /// <summary>
    /// The speed level the serve should be at — a pure function of the
    /// counters, so speed only ever rises within a serve, never falls.
    /// </summary>
    public static int SpeedLevel(int paddleHits, bool hitHighBrick, int currentLevel)
    {
        int level = currentLevel;
        if (paddleHits >= FirstSpeedUpHits)
            level = Math.Max(level, 1);
        if (paddleHits >= SecondSpeedUpHits)
            level = Math.Max(level, 2);
        if (paddleHits >= ThirdSpeedUpHits)
            level = Math.Max(level, 3);
        if (hitHighBrick)
            level = 4;
        return level;
    }

    /// <summary>
    /// Unit rebound direction off a paddle — 1976's four-exit table, one
    /// speed level longer. The manual carries the rule over verbatim: which
    /// portion of the paddle was struck decides everything ("the ball's angle
    /// of incidence is irrelevant"), and the same four sections apply after
    /// the paddle has shrunk to half width.
    /// </summary>
    public static Vector2 PaddleRebound(float offset, int speedLevel)
    {
        float degrees = MathF.Abs(offset) < 0.5f
            ? InnerAngles[speedLevel]
            : OuterAngles[speedLevel];

        // Dead-center still exits at the inner angle, to the right by
        // convention — no ball is ever exactly vertical (same law as 1976).
        float side = offset >= 0f ? 1f : -1f;

        float radians = MathHelper.ToRadians(degrees) * side;
        return new Vector2(MathF.Sin(radians), -MathF.Cos(radians));
    }

    /// <summary>The serve is unchanged from 1976: downward ("one component of
    /// its direction will always be toward the paddle"), random side, random
    /// angle — so both serve functions delegate to the 1976 ones.</summary>
    public static Vector2 ServeDirection(Random rng) => ClassicRules.ServeDirection(rng);

    /// <summary>Where a served ball materializes — the 1976 spot.</summary>
    public static Vector2 ServePosition(Random rng) => ClassicRules.ServePosition(rng);

    /// <summary>
    /// Direction for a captive ball waking up inside its cavity: anywhere on
    /// the circle — it has nowhere to go but the cavity walls anyway.
    /// </summary>
    public static Vector2 CaptiveDirection(Random rng)
    {
        float radians = (float)rng.NextDouble() * MathHelper.TwoPi;
        return new Vector2(MathF.Sin(radians), MathF.Cos(radians));
    }
}
