using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// DOUBLE: two paddles stacked on one set of controls, two balls per serve.
/// The manual's serve economy: both balls are "counted as one serve" — the
/// second materializes moments after the first ("...otherwise the second
/// ball is served"), losing the second costs nothing ("SERVE IS NOT LOST IN
/// THIS CASE"), and every brick is worth double while both balls fly. The
/// wall regenerates forever — no 1976 two-wall cap, no winning, only a high
/// score. Everything here is the second serve and the endless wall; the
/// stacked paddles are session data (GameSession builds two), not a rule.
/// </summary>
public sealed class SuperDoublePlayingState : SuperPlayingState
{
    private const float SecondServeDelay = 1f;

    // One timer, no "served" flag: the timer crossing the threshold IS the
    // event, and once past it the first check returns forever.
    private float _serveTimer;

    public SuperDoublePlayingState(GameStateManager manager) : base(manager) { }

    protected override void UpdateVariant(float dt)
    {
        if (_serveTimer >= SecondServeDelay)
            return;
        _serveTimer += dt;
        if (_serveTimer < SecondServeDelay)
            return;

        var ball = new Ball { Position = SuperRules.ServePosition(Session.Rng) };
        ball.OverrideSpeed(SuperRules.Speeds[SpeedLevel]); // join the ladder mid-rung
        ball.Velocity = SuperRules.ServeDirection(Session.Rng) * ball.Speed;

        // No arming call: a new ball defaults to unarmed, so it too must
        // meet a paddle before it can harm a brick.
        Session.Balls.Add(ball);
        AudioBank.PowerUpCatch?.Play();
    }

    protected override void CheckWallRespawn()
    {
        if (Session.Bricks.Count == 0)
            ArmWallRebuild();
    }
}
