using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.Entities;

/// <summary>
/// The ball: a center position plus a velocity in pixels per second. It knows
/// how to fly, stick to the paddle between serves, bounce off the paddle, and
/// speed up as bricks fall — but it never decides *when* any of that happens;
/// PlayingState drives it. Entities here are data plus motion; rules live in
/// the states.
/// </summary>
public class Ball
{
    public const int Size = 10;

    private const float InitialSpeed = 320f;
    private const float MaxSpeed = 560f;
    private const float SpeedRampPerBrick = 8f;
    private const float MaxBounceAngle = MathHelper.Pi / 3f; // 60° from vertical
    private const float MaxLaunchAngle = MathHelper.Pi / 7f; // ~26° from vertical

    // Public fields rather than properties: Vector2 is a mutable struct, and
    // `ball.Position.X += ...` only compiles against a field (CS1612 through a
    // property, which returns a copy). Idiomatic in XNA/MonoGame gameplay code.
    public Vector2 Position;
    public Vector2 Velocity;

    // Presentation-only flag, written by the 1978 states: true while the
    // pass-through rule says this ball cannot break bricks (not yet returned
    // by the paddle, or "boring" after a kill). The rule itself lives in
    // SuperPlayingState's side table; the ball only *wears* it. The tell
    // matters: an invisible rule and a collision bug look identical from the
    // player's chair, so a ball that sails through bricks must say so.
    public bool IsPhantom;

    public float Speed { get; private set; } = InitialSpeed;

    private Paddle _attachedTo;
    public bool IsAttached => _attachedTo != null;

    // Trail: the last N center positions in a ring buffer. Same GC-free shape
    // as the particle pool — a fixed array plus a write index that wraps with
    // modulo. Nothing is ever allocated or shifted; "oldest entry" is simply
    // "the slot the head will overwrite next".
    private const int TrailLength = 12;
    private readonly Vector2[] _trail = new Vector2[TrailLength];
    private int _trailHead;  // next slot to write
    private int _trailCount; // how many slots hold real data (< Length at start)

    public Rectangle Bounds => new(
        (int)(Position.X - Size / 2f), (int)(Position.Y - Size / 2f), Size, Size);

    public void AttachTo(Paddle paddle)
    {
        _attachedTo = paddle;
        Velocity = Vector2.Zero;
        Speed = InitialSpeed; // losing a life also resets the speed ramp
        _trailCount = 0;      // no ghost trail on the freshly served ball
        IsPhantom = false;    // pass-through is per-serve state; a new serve clears it
    }

    public void Launch(Random rng)
    {
        float angle = ((float)rng.NextDouble() * 2f - 1f) * MaxLaunchAngle;
        Velocity = new Vector2(MathF.Sin(angle), -MathF.Cos(angle)) * Speed;
        _attachedTo = null;
    }

    public void Update(float dt)
    {
        if (IsAttached)
        {
            Position = new Vector2(
                _attachedTo.Bounds.Center.X,
                _attachedTo.Bounds.Top - Size / 2f - 1);
            return;
        }

        // One trail sample per fixed 60 Hz tick gives evenly spaced ghosts
        // without any timestamp bookkeeping.
        _trail[_trailHead] = Position;
        _trailHead = (_trailHead + 1) % TrailLength;
        if (_trailCount < TrailLength)
            _trailCount++;

        Position += Velocity * dt;
    }

    /// <summary>
    /// The classic Breakout control mechanic: the exit angle depends on *where*
    /// the ball struck the paddle, not on the incoming angle. Center hit goes
    /// straight up; edge hits leave at up to MaxBounceAngle. This single
    /// mapping is what turns the paddle from a wall into an aiming device —
    /// it is the game-feel knob of the whole genre.
    /// </summary>
    public void BounceOffPaddle(Paddle paddle)
    {
        Rectangle p = paddle.Bounds;
        float offset = (Position.X - p.Center.X) / (p.Width / 2f);
        offset = MathHelper.Clamp(offset, -1f, 1f);

        float angle = offset * MaxBounceAngle;
        Velocity = new Vector2(MathF.Sin(angle), -MathF.Cos(angle)) * Speed;
        Position.Y = p.Top - Size / 2f; // lift clear so we can't hit twice
    }

    /// <summary>
    /// A second live ball for the multiball power-up: same position, same
    /// speed, velocity rotated by the given offset so the pack fans out
    /// instead of flying as one invisible stack. Standard 2D rotation —
    /// MonoGame has Vector2.Transform, but for a single rotation the two
    /// multiplies are clearer than building a Matrix.
    /// </summary>
    public Ball Split(float angleOffsetRadians)
    {
        float cos = MathF.Cos(angleOffsetRadians);
        float sin = MathF.Sin(angleOffsetRadians);

        // Speed's private setter is reachable here: `private` is per-class,
        // not per-instance, so Ball code may touch another Ball's internals.
        return new Ball
        {
            Position = Position,
            Speed = Speed,
            Velocity = new Vector2(
                Velocity.X * cos - Velocity.Y * sin,
                Velocity.X * sin + Velocity.Y * cos),
        };
    }

    public void RampSpeed()
    {
        Speed = MathF.Min(Speed + SpeedRampPerBrick, MaxSpeed);
        if (Velocity != Vector2.Zero)
            Velocity = Vector2.Normalize(Velocity) * Speed;
    }

    /// <summary>
    /// Set the speed outright, rescaling any in-flight velocity to match.
    /// The classic mode uses this for its four discrete speed steps, where
    /// RampSpeed's gentle per-brick climb would be the wrong model.
    /// </summary>
    public void OverrideSpeed(float speed)
    {
        Speed = speed;
        if (Velocity != Vector2.Zero)
            Velocity = Vector2.Normalize(Velocity) * Speed;
    }

    /// <summary>
    /// Take the ball out of play without removing it from the list: parked
    /// off-screen, motionless, trail cleared. The classic serve uses this —
    /// the 1976 ball is not carried on the paddle, it *materializes*
    /// mid-screen when served, so between serves there is nothing to show.
    /// </summary>
    public void Park()
    {
        _attachedTo = null;
        Velocity = Vector2.Zero;
        Position = new Vector2(-100f, -100f);
        _trailCount = 0;
        IsPhantom = false;
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        // A phantom ball draws at 40% strength, trail and all — "cannot break
        // bricks right now" rendered as a state the player can see coming,
        // and the snap back to full white is the "armed again" cue.
        float strength = IsPhantom ? 0.4f : 1f;

        // Trail first so the ball draws on top of it. Walk from oldest to
        // newest: index back from the head, oldest sample = furthest back.
        for (int i = 0; i < _trailCount; i++)
        {
            int index = (_trailHead - _trailCount + i + TrailLength) % TrailLength;

            // t runs 0 (oldest) -> 1 (newest); both size and alpha follow it.
            float t = (i + 1f) / (_trailCount + 1f);
            int size = Math.Max(2, (int)(Size * t * 0.8f));
            var rect = new Rectangle(
                (int)(_trail[index].X - size / 2f),
                (int)(_trail[index].Y - size / 2f), size, size);

            // `Color * float` premultiplies — fades cleanly under SpriteBatch's
            // default blend, same trick as the particles.
            spriteBatch.DrawRect(rect, Color.White * (t * t * 0.30f * strength));
        }

        spriteBatch.DrawRect(Bounds, Color.White * strength);
    }
}
