using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// The 1976 rules, live. Same entities as the modern game, different laws:
///
///  - Four discrete ball speeds (4th hit, 12th hit, instant max on orange/red)
///    instead of the modern per-brick ramp.
///  - One brick per trip: after a brick disappears, the ball must touch the
///    paddle or the backwall (top) before another may disappear. Dis-armed
///    contacts still rebound — the brick just survives.
///  - Four-segment paddle rebound (routing, not aiming) and never an exactly
///    vertical ball.
///  - Breaking through to the zone behind the wall halves the paddle for the
///    rest of the volley.
///  - Exactly two walls; the second materializes mid-volley on the next
///    paddle-or-backwall contact after the first is cleared. 448 points each,
///    896 total. One deviation from the cabinet: it let the ball bounce
///    around the empty court until your serves ran out — we end the run with
///    the win screen, because "nothing left to score" is a dull way to learn.
///
/// No power-ups, no multiball — those are 1986 ideas (and ours).
/// Compare side by side with PlayingState: that diff IS the design history.
/// </summary>
public sealed class ClassicPlayingState : GameState
{
    // Per-serve rule state. The state object is created fresh on every serve
    // (ClassicReadyState constructs a new one), so these reset by construction.
    private int _bricksThisServe;
    private int _speedLevel;
    private bool _armedToScore = true; // serve heads for the paddle anyway
    private bool _brokeOut;

    public ClassicPlayingState(GameStateManager manager) : base(manager) { }

    public override bool IsSimulation => true;

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Pause))
        {
            Manager.ChangeState(new PauseState(Manager, this));
            return;
        }

        Session.Paddles[0].Update(dt, input); // classic is one-player by definition

        Ball ball = Session.Balls[0]; // classic is strictly one ball
        ball.Update(dt);
        BounceOffWalls(ball);
        BounceOffPaddle(ball);
        HandleBrickCollision(ball);
        DetectBreakout(ball);

        Session.Bricks.RemoveAll(b => !b.Alive);

        if (ball.Position.Y - Ball.Size > Screen.Height)
        {
            OnBallLost();
            return;
        }

        if (Session.Bricks.Count == 0)
        {
            if (Session.WallNumber == 1)
                Session.AwaitingSecondWall = true; // spawns on next paddle/backwall touch
            else
                Manager.ChangeState(new GameOverState(Manager, won: true)); // 896 banked
        }
    }

    public override void Draw(SpriteBatch spriteBatch) => DrawWorldAndHud(spriteBatch);

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

            // The top IS the manual's "backwall": touching it re-arms brick
            // removal and is one of the two triggers for wall two. During a
            // breakout volley this is what lets the ball strip the back row
            // brick by brick — backwall, brick, backwall, brick.
            OnBackwallOrPaddleTouch();
        }

        if (bounced)
            AudioBank.WallHit.PlayVaried(Session.Rng);
    }

    private void BounceOffPaddle(Ball ball)
    {
        if (ball.Velocity.Y <= 0f)
            return;
        if (!ball.Bounds.Intersects(Session.Paddles[0].Bounds))
            return;

        // Where the modern game maps the hit position to a continuous angle,
        // 1976 hardware had four fixed exits. Same offset computation, then a
        // table lookup instead of multiplication — feel the difference in play.
        Rectangle p = Session.Paddles[0].Bounds;
        float offset = MathHelper.Clamp(
            (ball.Position.X - p.Center.X) / (p.Width / 2f), -1f, 1f);

        ball.Velocity = ClassicRules.PaddleRebound(offset, _speedLevel) * ball.Speed;
        ball.Position.Y = p.Top - Ball.Size / 2f;

        OnBackwallOrPaddleTouch();
        AudioBank.PaddleHit.PlayVaried(Session.Rng);
    }

    private void OnBackwallOrPaddleTouch()
    {
        _armedToScore = true;
        if (Session.AwaitingSecondWall)
            Session.SpawnSecondWall();
    }

    private void HandleBrickCollision(Ball ball)
    {
        foreach (Brick brick in Session.Bricks)
        {
            if (!brick.Alive)
                continue;

            HitSide side = CollisionHelper.GetCollisionSide(ball.Bounds, brick.Bounds);
            if (side == HitSide.None)
                continue;

            CollisionHelper.ReflectAndSeparate(ball, brick.Bounds, side);

            if (_armedToScore)
            {
                brick.Hit(); // classic bricks are 1 HP — always destroys
                _armedToScore = false;
                _bricksThisServe++;
                Session.Score += brick.ScoreValue;

                ApplySpeedRules(ball, brick);

                Session.Particles.Emit(brick.Bounds.Center.ToVector2(), brick.BaseColor, 18, Session.Rng);
                Session.Shake.Add(0.3f);
                AudioBank.BrickBreak.PlayVaried(Session.Rng);
            }
            else
            {
                // "Only one brick can disappear at a time" — a dis-armed ball
                // rebounds, but the brick stays. The duller sound is the tell.
                Session.Shake.Add(0.1f);
                AudioBank.BrickHit.PlayVaried(Session.Rng);
            }

            break; // one resolution per tick, as in the modern state
        }
    }

    private void ApplySpeedRules(Ball ball, Brick brick)
    {
        bool highRow = brick.ScoreValue >= ClassicRules.HighRowScore;
        int newLevel = ClassicRules.SpeedLevel(_bricksThisServe, highRow, _speedLevel);
        if (newLevel == _speedLevel)
            return;

        _speedLevel = newLevel;
        ball.OverrideSpeed(ClassicRules.Speeds[_speedLevel]);

        // Same cue as the 1978 state: the discrete jump needs announcing or
        // it feels like a glitch, not a rule.
        AudioBank.SpeedUp?.Play();
        Session.Particles.Emit(ball.Position, Color.White, 8, Session.Rng);
    }

    private void DetectBreakout(Ball ball)
    {
        if (_brokeOut || ball.Position.Y >= ClassicWall.BreakoutLineY)
            return;

        // The ball reached the zone between the rearmost row and the backwall:
        // that's the game's namesake event, and it costs half the paddle for
        // the rest of this volley.
        _brokeOut = true;
        Session.Paddles[0].ApplyClassicShrink();
        Session.Shake.Add(0.25f);
        AudioBank.PowerUpCatch?.Play(); // the rising sweep doubles as a fanfare
    }

    private void OnBallLost()
    {
        Session.Lives--;
        if (Session.Lives > 0)
            Manager.ChangeState(new LifeLostState(Manager));
        else
            Manager.ChangeState(new GameOverState(Manager, won: false));
    }
}
