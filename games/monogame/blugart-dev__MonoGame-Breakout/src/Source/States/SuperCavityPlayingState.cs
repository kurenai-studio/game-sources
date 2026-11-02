using Microsoft.Xna.Framework;
using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// CAVITY: one served ball, two more sealed inside 2x2 holes in the orange
/// wall. Captive balls bounce in place while the serve is live, but "the
/// bricks surrounding them do not disappear when struck by them" — they
/// rebound harmlessly. Note the symmetry with the base state's pass-through
/// rule: the player's boring ball harms bricks without rebounding, a captive
/// rebounds without harming. Open a cavity and the captive escapes through
/// the gap by plain physics — no scripted release — joins play already
/// scoring, and the multiplier climbs: x2 with two balls flying, x3 with all
/// three. Lose a ball, lose a multiplier step; only the served ball costs a
/// serve. The wall (cavities, captives and all) regenerates once the bonus
/// balls are spent.
/// </summary>
public sealed class SuperCavityPlayingState : SuperPlayingState
{
    public SuperCavityPlayingState(GameStateManager manager) : base(manager) { }

    protected override void UpdateVariant(float dt)
    {
        for (int i = Session.CaptiveBalls.Count - 1; i >= 0; i--)
        {
            Ball captive = Session.CaptiveBalls[i];
            if (captive.Velocity == Vector2.Zero)
                continue; // frozen between serves

            // The freed check runs BEFORE this tick's movement: a freed ball
            // is handed to the base loop, which moves it — moving it here too
            // would give it one double-length step on its first frame in play.
            if (IsFreed(captive))
            {
                Session.CaptiveBalls.RemoveAt(i);
                Session.Balls.Add(captive);
                captive.OverrideSpeed(SuperRules.Speeds[SpeedLevel]); // onto the serve's rung
                ArmBall(captive); // "the score doubles for each brick hit by
                // any one of the two balls" — it scores with no paddle touch
                Session.Shake.Add(0.2f);
                AudioBank.PowerUpCatch?.Play();
                continue;
            }

            captive.Update(dt);
            BounceOffBricks(captive);
        }
    }

    private void BounceOffBricks(Ball captive)
    {
        // Resolve EVERY overlapping brick, not first-found-then-stop. A
        // captive lives walled in, and a corner contact at top speed overlaps
        // two bricks in the same tick; resolving only one let the other keep
        // swallowing the ball until it slipped through a sealed wall — and
        // the freed check below would then bless the escape as a release.
        // Safe to resolve repeatedly because ReflectAndSeparate sets the
        // velocity sign outright instead of negating (see its comment).
        foreach (Brick brick in Session.Bricks)
        {
            if (!brick.Alive)
                continue;
            HitSide side = CollisionHelper.GetCollisionSide(captive.Bounds, brick.Bounds);
            if (side != HitSide.None)
                CollisionHelper.ReflectAndSeparate(captive, brick.Bounds, side);
        }
    }

    /// <summary>Freed once the ball's center leaves its hole — with a little
    /// slack, since collision separation can park the center a pixel outside
    /// while the ball is still walled in.</summary>
    private static bool IsFreed(Ball captive)
    {
        foreach (Rectangle hole in SuperWall.CavityHoles)
        {
            Rectangle slack = hole;
            slack.Inflate(4, 4);
            if (slack.Contains((int)captive.Position.X, (int)captive.Position.Y))
                return false;
        }
        return true;
    }

    protected override void OnBallLost(Ball ball)
    {
        // "...until the ball is missed. In this case they stop moving" — the
        // captives' clock is the served ball; freed balls play on without it.
        if (IsServeBall(ball))
            foreach (Ball captive in Session.CaptiveBalls)
                captive.Velocity = Vector2.Zero;
    }

    protected override void CheckWallRespawn()
    {
        // The manual is silent here; observed cabinet behavior: with bonus
        // balls still flying a cleared wall stays clear, and it regenerates
        // once a single active ball remains.
        if (Session.Bricks.Count == 0 && Session.Balls.Count <= 1)
            ArmWallRebuild();
    }

    protected override void OnWallRebuilt() => Session.WakeCaptiveBalls();
}
