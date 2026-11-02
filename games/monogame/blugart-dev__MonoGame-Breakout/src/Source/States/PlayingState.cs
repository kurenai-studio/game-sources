using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// The live simulation: ball flight, all collision responses, power-ups,
/// scoring, and the transitions out (life lost, game over, level cleared).
/// </summary>
public sealed class PlayingState : GameState
{
    private const float PowerUpDropChance = 0.15f;
    private const float DebrisDropChance = 0.10f;

    public PlayingState(GameStateManager manager) : base(manager) { }

    public override bool IsSimulation => true;

    public override void Update(float dt, InputHelper input)
    {
        if (input.WasActionJustPressed(GameAction.Pause))
        {
            Manager.ChangeState(new PauseState(Manager, this));
            return; // don't simulate the tick the player paused on
        }

        foreach (Paddle paddle in Session.Paddles)
            paddle.Update(dt, input);

        // Backwards so RemoveAt never shifts a ball we haven't visited yet.
        for (int i = Session.Balls.Count - 1; i >= 0; i--)
        {
            Ball ball = Session.Balls[i];
            ball.Update(dt);
            BounceOffWalls(ball);
            BounceOffPaddle(ball);
            HandleBrickCollision(ball);

            // With multiball, dropping a ball is only fatal when it's the last.
            if (ball.Position.Y - Ball.Size > Screen.Height)
                Session.Balls.RemoveAt(i);
        }

        // Dead bricks are culled once per tick, after every ball has had its
        // collision pass — mutating the list inside the per-ball loop would
        // invalidate the iteration for the balls still waiting.
        Session.Bricks.RemoveAll(b => !b.Alive);

        UpdatePowerUps(dt);

        if (Session.Balls.Count == 0)
        {
            OnBallLost();
        }
        else if (Session.LevelCleared)
        {
            // "You win" only exists after the last board; everything before
            // that is just another level transition.
            if (Session.HasNextLevel)
                Manager.ChangeState(new LevelClearedState(Manager));
            else
                Manager.ChangeState(new GameOverState(Manager, won: true));
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
        }

        if (bounced)
            AudioBank.WallHit.PlayVaried(Session.Rng);
    }

    private void BounceOffPaddle(Ball ball)
    {
        // Only while descending: once the ball bounces it overlaps the paddle
        // for a few frames, and re-bouncing every one of them would glue it down.
        if (ball.Velocity.Y <= 0f)
            return;

        // Whichever paddle the ball meets first owns the bounce; they guard
        // disjoint court halves, so at most one can intersect.
        foreach (Paddle paddle in Session.Paddles)
        {
            if (!ball.Bounds.Intersects(paddle.Bounds))
                continue;

            ball.BounceOffPaddle(paddle);
            AudioBank.PaddleHit.PlayVaried(Session.Rng);
            return;
        }
    }

    private void HandleBrickCollision(Ball ball)
    {
        foreach (Brick brick in Session.Bricks)
        {
            // A brick another ball already destroyed this tick is still in
            // the list (culling happens after the ball loop) — hitting it
            // again would pay its score twice.
            if (!brick.Alive)
                continue;

            HitSide side = CollisionHelper.GetCollisionSide(ball.Bounds, brick.Bounds);
            if (side == HitSide.None)
                continue;

            CollisionHelper.ReflectAndSeparate(ball, brick.Bounds, side);

            if (brick.Hit())
            {
                Session.Score += brick.ScoreValue;
                Session.Particles.Emit(brick.Bounds.Center.ToVector2(), brick.BaseColor, 18, Session.Rng);
                Session.Shake.Add(0.3f);
                ball.RampSpeed(); // difficulty ramps with progress — per ball
                AudioBank.BrickBreak.PlayVaried(Session.Rng);
                MaybeDropPowerUp(brick.Bounds.Center.ToVector2());
            }
            else
            {
                Session.Shake.Add(0.1f);
                AudioBank.BrickHit.PlayVaried(Session.Rng);
            }

            // One brick per ball per tick: after reflecting, a second
            // simultaneous overlap resolves cleanly on the next 60 Hz step
            // anyway, and processing both would double-flip the velocity.
            break;
        }
    }

    private void MaybeDropPowerUp(Vector2 origin)
    {
        // One roll, partitioned: [0, .15) drops a prize, [.15, .25) drops
        // debris, the rest drops nothing. Mutually exclusive outcomes from a
        // single random number — two independent rolls could drop both from
        // one brick, stacked on the same spot.
        double roll = Session.Rng.NextDouble();
        if (roll < PowerUpDropChance)
        {
            // Wide is the safer prize, so it's the more common one.
            PowerUpType type = Session.Rng.NextDouble() < 0.6
                ? PowerUpType.WidePaddle
                : PowerUpType.Multiball;
            Session.PowerUps.Add(new PowerUp(type, origin));
        }
        else if (roll < PowerUpDropChance + DebrisDropChance)
        {
            Session.PowerUps.Add(new PowerUp(PowerUpType.Debris, origin));
        }
    }

    private void UpdatePowerUps(float dt)
    {
        // Backwards so RemoveAt doesn't shift unvisited elements.
        for (int i = Session.PowerUps.Count - 1; i >= 0; i--)
        {
            PowerUp powerUp = Session.PowerUps[i];
            powerUp.Update(dt);

            Paddle catcher = CatchingPaddle(powerUp);
            if (catcher != null)
            {
                ApplyPowerUp(powerUp, catcher);
                if (powerUp.IsHazard)
                    AudioBank.DebrisHit.PlayVaried(Session.Rng);
                else
                    AudioBank.PowerUpCatch?.Play();
                Session.PowerUps.RemoveAt(i);
            }
            else if (powerUp.IsBelowScreen)
            {
                Session.PowerUps.RemoveAt(i);
            }
        }
    }

    private Paddle CatchingPaddle(PowerUp powerUp)
    {
        foreach (Paddle paddle in Session.Paddles)
            if (powerUp.Bounds.Intersects(paddle.Bounds))
                return paddle;
        return null;
    }

    private void ApplyPowerUp(PowerUp powerUp, Paddle catcher)
    {
        switch (powerUp.Type)
        {
            case PowerUpType.WidePaddle:
                catcher.ApplyWide(PowerUp.WidePaddleDuration); // the catch is personal in co-op
                break;
            case PowerUpType.Multiball:
                SpawnMultiball();
                break;
            case PowerUpType.Debris:
                catcher.ApplyShrink(PowerUp.DebrisShrinkDuration);
                // Negative feedback mirrors positive: the prize-catch plays a
                // rising tone, this shakes the screen and sprays dark chips —
                // the player must *feel* the difference before reading any text.
                Session.Shake.Add(0.25f);
                Session.Particles.Emit(
                    powerUp.Position, new Color(200, 70, 40), 12, Session.Rng);
                break;
        }
    }

    private void SpawnMultiball()
    {
        // Caught on the very tick the last ball dropped: nothing to clone,
        // and the life is already lost — let it fizzle.
        if (Session.Balls.Count == 0)
            return;

        // Cap the swarm: beyond this the screen is chaos, not challenge,
        // and every extra ball doubles the collision noise.
        const int maxBalls = 6;

        Ball source = Session.Balls[0];
        Session.Shake.Add(0.2f);
        for (int i = 0; i < 2 && Session.Balls.Count < maxBalls; i++)
        {
            float angle = (i == 0 ? 1f : -1f) * MathHelper.ToRadians(25f);
            Session.Balls.Add(source.Split(angle));
        }
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
