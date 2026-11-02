using System;
using Microsoft.Xna.Framework;

namespace Breakout.Systems;

/// <summary>
/// The 1976 Atari Breakout numbers, gathered in one place so the classic
/// states read like the original manual. Sourced from the machine's
/// Operation/Maintenance/Service Manual and the 1976 sales flyer:
///
///  - Four ball speeds. Each serve starts at the slowest; speed-ups occur on
///    the 4th hit and the 12th hit, and the ball jumps straight to the fourth
///    speed the moment any high-point (orange or red) brick is hit.
///  - The paddle rebounds the ball in one of four directions chosen solely by
///    which quarter of the paddle was struck — the incoming angle is
///    irrelevant — and the rebound angles become MORE perpendicular as the
///    ball gets faster.
///  - The ball is never allowed to travel exactly perpendicular to the paddle,
///    the bricks, or any boundary (a vertical ball over a gap would play
///    itself), so every angle here is non-zero.
///
/// Two reconstructions, both flagged because the manual gives no numbers:
/// the exact rebound angles (its Figure 3-4 is only a diagram), and what
/// counts as a "hit" for the 4/12 thresholds — we count destroyed bricks.
/// Cycle-exact values would need the TTL schematic or MAME's netlist.
/// </summary>
public static class ClassicRules
{
    // Serves per game: we inherit GameSession.StartingLives = 3, which happens
    // to be the cabinet's standard operator setting (the other option was 5).

    /// <summary>Pixels per second for speed levels 0-3.</summary>
    public static readonly float[] Speeds = { 280f, 350f, 430f, 560f };

    public const int FirstSpeedUpHits = 4;
    public const int SecondSpeedUpHits = 12;

    /// <summary>Orange (5) and red (7) bricks force the top speed instantly.</summary>
    public const int HighRowScore = 5;

    // Rebound angles in degrees from vertical, per speed level — the inner
    // two paddle quarters send the ball steeply, the outer two send it wide,
    // and every angle tightens toward vertical as speed rises (reconstructed
    // values; see the class summary).
    private static readonly float[] InnerAngles = { 32f, 28f, 24f, 20f };
    private static readonly float[] OuterAngles = { 58f, 52f, 46f, 40f };

    /// <summary>
    /// The speed level the ball should be at, given the serve's progress.
    /// Pure function of the counters, so it can never accidentally skip a
    /// step down — speed only ever rises within a serve.
    /// </summary>
    public static int SpeedLevel(int bricksThisServe, bool hitHighRow, int currentLevel)
    {
        int level = currentLevel;
        if (bricksThisServe >= FirstSpeedUpHits)
            level = Math.Max(level, 1);
        if (bricksThisServe >= SecondSpeedUpHits)
            level = Math.Max(level, 2);
        if (hitHighRow)
            level = 3;
        return level;
    }

    /// <summary>
    /// Unit rebound direction off the paddle. Offset is -1..1 across the
    /// paddle face; the sign picks the side, the magnitude picks inner vs
    /// outer quarter. Note what is *absent* compared to the modern game's
    /// continuous aiming: only four exits exist, which is why classic
    /// Breakout feels like routing, not aiming.
    /// </summary>
    public static Vector2 PaddleRebound(float offset, int speedLevel)
    {
        float degrees = MathF.Abs(offset) < 0.5f
            ? InnerAngles[speedLevel]
            : OuterAngles[speedLevel];

        // A dead-center hit still exits at the inner angle — to the right, by
        // convention. Math.Sign would return 0 and make the ball vertical,
        // which the original hardware never allowed.
        float side = offset >= 0f ? 1f : -1f;

        float radians = MathHelper.ToRadians(degrees) * side;
        return new Vector2(MathF.Sin(radians), -MathF.Cos(radians));
    }

    /// <summary>
    /// Where a served ball materializes: "about midway along the TV screen"
    /// (vertically midway, safely below the wall), random X so the player
    /// can't camp. Super Breakout serves from the same spot, so SuperRules
    /// delegates here — one encoding of a rule two games share.
    /// </summary>
    public static Vector2 ServePosition(Random rng)
        => new(200f + (float)rng.NextDouble() * (Screen.Width - 400), 280f);

    /// <summary>
    /// Unit direction for a fresh serve: downward (the 1976 ball is served
    /// *at* you, not launched by you), random side, 12-50 degrees off
    /// vertical so it is neither perpendicular nor a near-horizontal crawl.
    /// </summary>
    public static Vector2 ServeDirection(Random rng)
    {
        float degrees = 12f + (float)rng.NextDouble() * 38f;
        float side = rng.Next(2) == 0 ? 1f : -1f;

        float radians = MathHelper.ToRadians(degrees) * side;
        return new Vector2(MathF.Sin(radians), MathF.Cos(radians)); // +Y: toward the paddle
    }
}
