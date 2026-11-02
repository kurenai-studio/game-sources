using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// The physics every 1978 game shares; the three subclasses are the three
/// game variants on the cabinet's game-select knob. Compare with
/// ClassicPlayingState — the sequel kept the materializing serve, the
/// discrete speed ladder and the four-exit paddle, and changed three laws:
///
///  - The pass-through rule replaces "one brick per trip". A ball the paddle
///    has not returned yet sails through bricks untouched, and after every
///    destroyed brick the ball *bores*: it keeps sailing through for four
///    rows, or until it touches the paddle or the top boundary. 1976's
///    dis-armed ball rebounded and spared the brick; 1978's spares the brick
///    and does not even rebound.
///  - The half-width penalty moved: it now triggers on top-boundary contact
///    and heals at the next serve.
///  - Scores multiply by the number of balls in play — the sequel exists to
///    put more than one ball on screen — and only the *served* ball costs a
///    serve when lost. Bonus balls (Double's second serve, Cavity's freed
///    captives) are free.
/// </summary>
public abstract class SuperPlayingState : GameState
{
    // Per-serve rule state, reset by construction like the classic state:
    // SuperReadyState builds a fresh playing state on every serve.
    private int _paddleHits;
    private bool _paddleShrunk;
    private bool _awaitingWall;

    /// <summary>Current rung of the five-speed ladder, shared by every ball.</summary>
    protected int SpeedLevel { get; private set; }

    // The serve's life-bearer, identified by reference: whatever ball existed
    // when play began is "the" ball; everything a subclass adds later is a
    // bonus ball whose loss costs nothing.
    private readonly Ball _serveBall;

    // Per-ball rule state in a side table rather than fields on Ball — the
    // pass-through rule is 1978 law, not a property of balls in general, so
    // it lives and dies with this state object.
    private readonly Dictionary<Ball, BallRules> _rules = new();

    private sealed class BallRules
    {
        public bool Armed;    // the paddle has returned this ball this serve
        public bool Boring;   // passing through bricks since the last kill
        public float BoreStartY;
    }

    protected SuperPlayingState(GameStateManager manager) : base(manager)
        => _serveBall = Session.Balls[0];

    public override bool IsSimulation => true; // covers all three variants

    /// <summary>x2/x3 while bonus balls fly — the manual's score tables are
    /// just "base value times balls in the playfield".</summary>
    protected int Multiplier => Session.Balls.Count;

    protected bool IsServeBall(Ball ball) => ball == _serveBall;

    /// <summary>
    /// Subclasses call this when their wall should regenerate. Like 1976's
    /// second wall, it materializes on a paddle-or-top touch — and only once
    /// every ball is clear of the wall band, so no ball (the toucher OR any
    /// other; Double and Cavity fly several) is standing inside the new
    /// bricks. Idempotent, so per-tick re-arming is harmless.
    /// </summary>
    protected void ArmWallRebuild() => _awaitingWall = true;

    /// <summary>Mark a ball as already returned by the paddle. Cavity's freed
    /// captives need this — they score at once, no paddle touch required.
    /// (New balls default to unarmed via the rule table's lazy entry.)</summary>
    protected void ArmBall(Ball ball) => RulesOf(ball).Armed = true;

    private BallRules RulesOf(Ball ball)
    {
        if (!_rules.TryGetValue(ball, out BallRules rules))
            _rules[ball] = rules = new BallRules();
        return rules;
    }

    // Variant hooks — the whole difference between Double, Cavity and
    // Progressive hangs off these five.
    protected virtual void UpdateVariant(float dt) { }
    protected virtual void OnPaddleHit(Ball ball) { }
    protected virtual void CheckWallRespawn() { }
    protected virtual void OnWallRebuilt() { }
    protected virtual void OnBallLost(Ball ball) { }

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Pause))
        {
            Manager.ChangeState(new PauseState(Manager, this));
            return;
        }

        foreach (Paddle paddle in Session.Paddles)
            paddle.Update(dt, input);

        UpdateVariant(dt);

        for (int i = Session.Balls.Count - 1; i >= 0; i--)
        {
            Ball ball = Session.Balls[i];
            ball.Update(dt);
            BounceOffWalls(ball);
            BounceOffPaddles(ball);
            HandleBrickCollision(ball);

            if (ball.Position.Y - Ball.Size > Screen.Height)
            {
                Session.Balls.RemoveAt(i);
                _rules.Remove(ball);
                LoseBall(ball);
            }
        }

        Session.Bricks.RemoveAll(b => !b.Alive);

        if (Session.Balls.Count == 0)
        {
            // The serve ends only when the playfield is empty — losing one
            // ball of several just drops the multiplier and plays on.
            if (Session.Lives > 0)
                Manager.ChangeState(new LifeLostState(Manager));
            else
                Manager.ChangeState(new GameOverState(Manager, won: false));
            return;
        }

        CheckWallRespawn();
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        DrawWorldAndHud(spriteBatch);

        // The doubled/tripled scoring is invisible without a tell. Below the
        // score line (which is ~28 px tall) and above the wall top (y = 70).
        // Constant strings, not $"x{Multiplier}" — this runs at 60 Hz, and
        // the HUD's no-garbage habit (see GameSession's cached score text)
        // applies here too. At most three balls can ever exist.
        if (Multiplier > 1)
            spriteBatch.DrawShadowedText(Font, Multiplier == 2 ? "x2" : "x3",
                new Vector2(12, 40), Color.Gold);
    }

    private void LoseBall(Ball ball)
    {
        // Only the served ball burns a serve. Lives can read 0 while bonus
        // balls keep a doomed serve alive — game over waits for the last one.
        if (ball == _serveBall)
            Session.Lives--;
        OnBallLost(ball);
    }

    private void BounceOffWalls(Ball ball)
    {
        const float half = Ball.Size / 2f;
        bool bounced = false;

        if (ball.Position.X < half)
        {
            ball.Position.X = half;
            ball.Velocity.X = MathF.Abs(ball.Velocity.X);
            bounced = true;
        }
        else if (ball.Position.X > Screen.Width - half)
        {
            ball.Position.X = Screen.Width - half;
            ball.Velocity.X = -MathF.Abs(ball.Velocity.X);
            bounced = true;
        }

        if (ball.Position.Y < half)
        {
            ball.Position.Y = half;
            ball.Velocity.Y = MathF.Abs(ball.Velocity.Y);
            bounced = true;
            OnTopBoundary(ball);
        }

        if (bounced)
            AudioBank.WallHit.PlayVaried(Session.Rng);
    }

    private void OnTopBoundary(Ball ball)
    {
        RulesOf(ball).Boring = false; // the top ends a bore, like the paddle

        // "Immediately on hitting the uppermost boundary at the top of the
        // screen the paddle(s) will reduce to half its width until the next
        // serve" — note the manual's plural: Double shrinks both. Where 1976
        // punished crossing the breakout line, 1978 punishes the touch itself.
        if (!_paddleShrunk)
        {
            _paddleShrunk = true;
            foreach (Paddle paddle in Session.Paddles)
                paddle.ApplyClassicShrink();
            Session.Shake.Add(0.25f);
            AudioBank.PowerUpCatch?.Play(); // the same fanfare 1976 uses
        }

        WallTouchPoint();
    }

    private void BounceOffPaddles(Ball ball)
    {
        // The velocity check is also the manual's one-sided upper paddle
        // ("they will not bounce off the bottom of the upper paddle") falling
        // out of the general rule: a rising ball never collides with any
        // paddle, so it sails up through Double's top paddle for free.
        if (ball.Velocity.Y <= 0f)
            return;

        foreach (Paddle paddle in Session.Paddles)
        {
            if (!ball.Bounds.Intersects(paddle.Bounds))
                continue;

            Rectangle p = paddle.Bounds;
            float offset = MathHelper.Clamp(
                (ball.Position.X - p.Center.X) / (p.Width / 2f), -1f, 1f);

            _paddleHits++;
            ApplySpeedRules(hitHighBrick: false);

            ball.Velocity = SuperRules.PaddleRebound(offset, SpeedLevel) * ball.Speed;
            ball.Position.Y = p.Top - Ball.Size / 2f;

            BallRules rules = RulesOf(ball);
            rules.Armed = true;   // "the player must hit the ball first"
            rules.Boring = false;

            WallTouchPoint();
            OnPaddleHit(ball);
            AudioBank.PaddleHit.PlayVaried(Session.Rng);
            return;
        }
    }

    private void WallTouchPoint()
    {
        if (!_awaitingWall)
            return;

        // Wait out any ball still inside the wall band — with several balls
        // in play, "someone touched the paddle" doesn't mean the airspace is
        // clear. The rebuild stays armed; touches are frequent.
        foreach (Ball ball in Session.Balls)
            if (ball.Bounds.Bottom > SuperWall.WallTop && ball.Bounds.Top < SuperWall.WallBottom)
                return;

        _awaitingWall = false;
        Session.RebuildSuperWall();
        OnWallRebuilt();
    }

    private void HandleBrickCollision(Ball ball)
    {
        BallRules rules = RulesOf(ball);

        if (rules.Boring && MathF.Abs(ball.Position.Y - rules.BoreStartY)
                >= SuperRules.BoreRows * SuperWall.CellHeight)
            rules.Boring = false;

        // Keep the ball's ghost rendering in lockstep with the rule. Set
        // every tick rather than at each transition — arming, boring and
        // bore-expiry all change it, and one assignment can't drift.
        ball.IsPhantom = !rules.Armed || rules.Boring;

        // The pass-through rule: an unarmed or boring ball ignores bricks —
        // no rebound, no damage. (1976's dis-armed ball: rebound, no damage.
        // Two games, two answers to "what may a ball that cannot score do?")
        if (!rules.Armed || rules.Boring)
            return;

        foreach (Brick brick in Session.Bricks)
        {
            if (!brick.Alive)
                continue;

            HitSide side = CollisionHelper.GetCollisionSide(ball.Bounds, brick.Bounds);
            if (side == HitSide.None)
                continue;

            CollisionHelper.ReflectAndSeparate(ball, brick.Bounds, side);
            brick.Hit(); // super bricks are 1 HP, like 1976

            Session.Score += brick.ScoreValue * Multiplier;
            ApplySpeedRules(hitHighBrick: brick.ScoreValue >= SuperRules.HighBrickScore);

            rules.Boring = true;
            rules.BoreStartY = ball.Position.Y;
            ball.IsPhantom = true; // ghost this frame too, not from next tick

            Session.Particles.Emit(brick.Bounds.Center.ToVector2(), brick.BaseColor, 18, Session.Rng);
            Session.Shake.Add(0.3f);
            AudioBank.BrickBreak.PlayVaried(Session.Rng);
            break; // one resolution per tick, as everywhere else
        }
    }

    private void ApplySpeedRules(bool hitHighBrick)
    {
        int newLevel = SuperRules.SpeedLevel(_paddleHits, hitHighBrick, SpeedLevel);
        if (newLevel == SpeedLevel)
            return;

        SpeedLevel = newLevel;
        // The ladder stepping is a discrete event the player must react to —
        // especially the instant jump to top speed off a 5/7 brick, which
        // with no cue reads as the game glitching. A zip and a white spark
        // on each ball mark the moment. (Sparks draw from Session.Rng like
        // all effects, so replays consume the same stream.)
        AudioBank.SpeedUp?.Play();
        // One serve, one speed: every ball in play jumps together, so
        // Double's pair and Cavity's freed captives stay on the same rung.
        foreach (Ball ball in Session.Balls)
        {
            ball.OverrideSpeed(SuperRules.Speeds[SpeedLevel]);
            Session.Particles.Emit(ball.Position, Color.White, 8, Session.Rng);
        }
    }
}
