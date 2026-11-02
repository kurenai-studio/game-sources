using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Entities;
using Breakout.Systems;

namespace Breakout;

/// <summary>
/// Everything one run of the game owns: the entities, the score, the lives,
/// the effects. States (Ready/Playing/...) are *modes of operating on* this
/// data — the data lives here so switching state never moves the world around.
/// Starting a new game is simply `new GameSession()`.
/// </summary>
public class GameSession
{
    public const int StartingLives = 3;

    // The run's level sequence. Adding a level is two steps: drop the .txt
    // into Content/Levels and list its path here — nothing else changes.
    private static readonly string[] LevelPaths =
    {
        "Content/Levels/level01.txt",
        "Content/Levels/level02.txt",
        "Content/Levels/level03.txt",
    };

    public static int LevelCount => LevelPaths.Length; // the title screen's level select needs the range

    // Start level one past the real levels = generated boards, forever. A
    // sentinel rather than a flag so it travels everywhere a start level
    // already goes (restart, replays) without widening any signature.
    public bool IsProcedural => StartLevelIndex >= LevelPaths.Length;

    // Seeded, and the seed is kept. `new Random()` is time-seeded anyway —
    // the run was always going to be "random from some seed"; *naming* that
    // seed is the one-line change that turns random into reproducible, and
    // it is what makes the replay system possible. Everything stochastic in
    // a run (launch angles, drop rolls, SFX pitch, shake) draws from this
    // single stream, so same seed + same inputs = the same run, bit for bit.
    public readonly int Seed;
    public readonly Random Rng;

    // A list, not a single Paddle — local co-op did to the paddle what
    // multiball did to the ball. Same ripple, second rehearsal: every
    // consumer that said "the paddle" (movement, ball bounce, power-up
    // catch, serve attach) had to decide what it means when there are two.
    public readonly List<Paddle> Paddles = new();

    // A list, not a single Ball — the multiball power-up was the feature that
    // forced this. Worth noticing how far the one-to-many change rippled:
    // every consumer that said "the ball" (serve, collision, loss check,
    // debug overlay) had to decide what it means when there are several.
    public readonly List<Ball> Balls = new();

    public List<Brick> Bricks { get; private set; }

    // Cavity Super Breakout only: balls sealed inside the wall's two holes.
    // Deliberately NOT in Balls, because they are not "in play" — they can't
    // be lost, don't score, and don't count toward the score multiplier.
    // Freeing one means moving it from this list to Balls.
    public readonly List<Ball> CaptiveBalls = new();

    // Holds prizes AND debris hazards: the fall/catch pipeline is identical,
    // only the catch's *meaning* differs (PowerUpType decides at apply time).
    public readonly List<PowerUp> PowerUps = new();
    public readonly ParticleSystem Particles = new();
    public readonly ScreenShake Shake;

    public int Score;
    public int Lives = StartingLives;
    public int LevelIndex { get; private set; } // 0-based; the HUD shows +1

    public GameMode Mode { get; }
    public int StartLevelIndex { get; } // modern: where the title screen started this run

    // Which high-score table this run competes in. Endless generated runs
    // get their own — comparing an unbounded score against a three-level
    // ceiling isn't a contest. Built once: Draw asks every frame.
    public string ScoreTable { get; }

    /// <summary>The table key for a mode/procedural pair — static so the
    /// title screen can ask before any session exists, and so the key is
    /// spelled in exactly one place.</summary>
    public static string ScoreTableFor(GameMode mode, bool procedural)
        => procedural ? $"{mode}-Random" : mode.ToString();

    // Classic-mode wall progression. The 1976 game is exactly two walls: when
    // the first is cleared, AwaitingSecondWall arms, and the wall materializes
    // mid-volley on the ball's next paddle-or-backwall contact (the manual's
    // rule — no interstitial, no new serve).
    public int WallNumber { get; private set; } = 1;
    public bool AwaitingSecondWall { get; set; }

    // Progressive Super Breakout only: how many rows have entered at the top
    // so far. Session data, not playing-state data: the endless four-bricks/
    // four-blanks pattern must continue seamlessly across serves, and a
    // playing state dies with its serve.
    public int ProgressiveRowPhase;

    public bool IsSuper => Mode is GameMode.SuperDouble
        or GameMode.SuperCavity or GameMode.SuperProgressive;

    // A generated run has no last board — it ends when the lives do.
    public bool HasNextLevel => IsProcedural || LevelIndex + 1 < LevelPaths.Length;

    // Cached HUD text: $"SCORE {Score}" allocates a new string every call, and
    // DrawHud runs every frame. Desktop GC absorbs this easily, but rebuilding
    // a string 60 times a second when it changes a few times a minute is the
    // kind of habit that matters on consoles — so cache it and rebuild only
    // when the value actually changed.
    private string _scoreText;
    private int _scoreTextValue = -1;
    private string _levelText;
    private int _levelTextValue = -1;

    public GameSession(GameMode mode, int startLevel = 0, int? seed = null)
    {
        // No seed given = a fresh run (seeded from the clock, like new
        // Random() would have); a recorded seed = a replay reliving that run.
        Seed = seed ?? Environment.TickCount;
        Rng = new Random(Seed);

        Mode = mode;
        StartLevelIndex = startLevel;
        LevelIndex = IsProcedural ? 0 : startLevel; // generated runs count boards from one
        ScoreTable = ScoreTableFor(mode, IsProcedural);
        Shake = new ScreenShake(Rng);
        Bricks = mode switch
        {
            GameMode.Classic => ClassicWall.Build(),
            GameMode.SuperDouble => SuperWall.BuildDouble(),
            GameMode.SuperCavity => SuperWall.BuildCavity(),
            GameMode.SuperProgressive => SuperWall.BuildProgressiveBoard(),
            _ => IsProcedural ? GenerateBoard() : LevelLoader.Load(LevelPaths[startLevel]),
        };

        if (mode == GameMode.Coop)
        {
            // Two paddles, two action sets, half a court each. P1 keeps the
            // mouse; P2 gets the arrows and the gamepad.
            Paddles.Add(new Paddle(GameAction.P1MoveLeft, GameAction.P1MoveRight,
                useMouse: true, 0f, Screen.Width / 2f));
            Paddles.Add(new Paddle(GameAction.P2MoveLeft, GameAction.P2MoveRight,
                useMouse: false, Screen.Width / 2f, Screen.Width, new Color(170, 190, 255)));
        }
        else if (mode == GameMode.SuperDouble)
        {
            // The 1978 "Double" cabinet: two paddles stacked on ONE knob, so
            // both read the same default bindings — contrast with co-op
            // above, where two paddles mean two players. The manual never
            // documents the vertical gap; this spacing matches footage.
            Paddles.Add(new Paddle());
            Paddles.Add(new Paddle(GameAction.MoveLeft, GameAction.MoveRight,
                useMouse: true, 0f, Screen.Width,
                new Color(170, 190, 255), Paddle.DefaultY - 36));
        }
        else
        {
            Paddles.Add(new Paddle());
        }

        if (mode == GameMode.SuperCavity)
            SpawnCaptiveBalls();

        if (mode == GameMode.Classic)
            PrepareClassicServe();
        else if (IsSuper)
            PrepareSuperServe();
        else
            ResetForServe();
    }

    /// <summary>
    /// Back to exactly one ball, attached to the paddle — the serve position.
    /// Runs on every ReadyState entry, which is what cleans up leftover
    /// multiballs after a lost life (Balls may be empty) or a cleared level
    /// (Balls may hold several).
    /// </summary>
    public void ResetForServe()
    {
        EnsureSingleBall();
        Balls[0].AttachTo(Paddles[0]); // in co-op, player one carries the serve
    }

    /// <summary>
    /// The classic counterpart: the 1976 ball is never carried on the paddle —
    /// it materializes mid-screen on serve — so between serves the ball is
    /// parked off-screen. The paddle also recovers from the half-width
    /// breakout penalty here: the manual ties the penalty to the volley.
    /// </summary>
    public void PrepareClassicServe()
    {
        EnsureSingleBall();
        Balls[0].Park();
        Paddles[0].ResetWidth(); // classic is one-player by definition
    }

    /// <summary>
    /// The Super Breakout serve prep: park the ball like classic (the 1978
    /// serve also materializes mid-screen), heal every paddle from the
    /// half-width penalty (the manual: "until the next serve"), and freeze
    /// Cavity's captives ("they stop moving, and remain motionless ... until
    /// the next ball is served").
    /// </summary>
    public void PrepareSuperServe()
    {
        EnsureSingleBall();
        Balls[0].Park();
        foreach (Paddle paddle in Paddles)
            paddle.ResetWidth();
        foreach (Ball captive in CaptiveBalls)
            captive.Velocity = Vector2.Zero;
    }

    private void EnsureSingleBall()
    {
        if (Balls.Count == 0)
            Balls.Add(new Ball());
        else if (Balls.Count > 1)
            Balls.RemoveRange(1, Balls.Count - 1);
    }

    /// <summary>Classic only: restore the full 8x14 wall as wall two.</summary>
    public void SpawnSecondWall()
    {
        WallNumber = 2;
        AwaitingSecondWall = false;
        Bricks = ClassicWall.Build();
    }

    /// <summary>
    /// Double/Cavity: a fresh wall, forever — the 1978 cabinet has no 1976
    /// two-wall cap ("when they are all gone a new wall forms"). Cavity's
    /// rebuild brings fresh captive balls with it; they spawn motionless and
    /// a state decides when they wake.
    /// </summary>
    public void RebuildSuperWall()
    {
        if (Mode == GameMode.SuperDouble)
        {
            Bricks = SuperWall.BuildDouble();
        }
        else if (Mode == GameMode.SuperCavity)
        {
            Bricks = SuperWall.BuildCavity();
            SpawnCaptiveBalls();
        }
    }

    private void SpawnCaptiveBalls()
    {
        CaptiveBalls.Clear();
        foreach (Rectangle hole in SuperWall.CavityHoles)
        {
            var captive = new Ball();
            captive.Park(); // motionless "prior to serving the ball"
            captive.Position = hole.Center.ToVector2();
            CaptiveBalls.Add(captive);
        }
    }

    /// <summary>Cavity: set any motionless captive bouncing — on serve, and
    /// when a mid-volley wall rebuild brings fresh captives into a live one.</summary>
    public void WakeCaptiveBalls()
    {
        foreach (Ball captive in CaptiveBalls)
            if (captive.Velocity == Vector2.Zero)
            {
                captive.OverrideSpeed(SuperRules.Speeds[0]);
                captive.Velocity = SuperRules.CaptiveDirection(Rng) * captive.Speed;
            }
    }

    /// <summary>
    /// Load the next board. Score and lives carry across — the *run* is the
    /// unit of play, a level is just the current wall. Ball speed does not
    /// carry: ReadyState re-attaches the ball, which resets the ramp, so each
    /// level climbs from base speed again instead of starting at the ceiling.
    /// That asymmetry (keep progress, reset difficulty) is the standard arcade
    /// answer to the carry-or-reset design question.
    /// </summary>
    public void AdvanceLevel()
    {
        LevelIndex++;
        PowerUps.Clear(); // falling pickups belong to the previous board
        Bricks = IsProcedural ? GenerateBoard() : LevelLoader.Load(LevelPaths[LevelIndex]);
    }

    // Same parser as the .txt levels, fed from a string instead of a file —
    // see BoardGenerator for why that reuse is the whole point. Drawing from
    // Rng keeps generated runs replayable: the replay's session re-seeds the
    // same stream, so it re-rolls the same boards.
    private List<Brick> GenerateBoard()
        => LevelLoader.Parse(new StringReader(BoardGenerator.Generate(Rng, LevelIndex)));

    // Destroyed bricks are removed from the list, so "cleared" means only
    // unbreakable ones remain. A plain loop rather than LINQ's All():
    // PlayingState asks this every simulation tick, and Enumerable methods
    // box List<T>'s struct enumerator — a small allocation, 60 times a
    // second. Same no-garbage habit as the cached HUD strings below.
    public bool LevelCleared
    {
        get
        {
            foreach (Brick brick in Bricks)
                if (!brick.IsUnbreakable)
                    return false;
            return true;
        }
    }

    /// <summary>
    /// Effects animate in every state — particles keep falling and the shake
    /// keeps settling even on the game-over screen.
    /// </summary>
    public void UpdateEffects(float dt)
    {
        Particles.Update(dt);
        Shake.Update(dt);

        // Brick entrance and scroll-slide are presentation, not simulation —
        // they animate a draw offset while Bounds stay authoritative — so
        // they tick with the effects (and therefore freeze correctly when
        // PauseState freezes them).
        foreach (Brick brick in Bricks)
            brick.UpdateAnimations(dt);
    }

    public void DrawWorld(SpriteBatch spriteBatch)
    {
        foreach (Brick brick in Bricks)
            brick.Draw(spriteBatch);
        foreach (PowerUp powerUp in PowerUps)
            powerUp.Draw(spriteBatch);
        foreach (Paddle paddle in Paddles)
            paddle.Draw(spriteBatch);
        foreach (Ball ball in Balls)
            ball.Draw(spriteBatch);
        foreach (Ball captive in CaptiveBalls)
            captive.Draw(spriteBatch); // sealed in, but drawn like any ball
        Particles.Draw(spriteBatch);
    }

    public void DrawHud(SpriteBatch spriteBatch, SpriteFont font)
    {
        if (_scoreTextValue != Score)
        {
            _scoreTextValue = Score;
            _scoreText = $"SCORE {Score}";
        }
        spriteBatch.DrawShadowedText(font, _scoreText, new Vector2(12, 8), Color.White);

        int levelValue = Mode == GameMode.Classic ? WallNumber : LevelIndex;
        if (_levelTextValue != levelValue)
        {
            _levelTextValue = levelValue;
            _levelText = Mode switch
            {
                GameMode.Classic => $"CLASSIC - WALL {WallNumber}",
                GameMode.SuperDouble => "SUPER - DOUBLE",
                GameMode.SuperCavity => "SUPER - CAVITY",
                GameMode.SuperProgressive => "SUPER - PROGRESSIVE",
                _ when IsProcedural => $"RANDOM - BOARD {LevelIndex + 1}",
                _ => $"LEVEL {LevelIndex + 1}",
            };
        }
        spriteBatch.DrawCenteredText(font, _levelText,
            new Vector2(Screen.Width / 2f, 16), new Color(150, 150, 165), 0.75f);

        // Lives as little paddle icons, arcade-style.
        for (int i = 0; i < Lives; i++)
            spriteBatch.DrawRect(
                new Rectangle(Screen.Width - 12 - (i + 1) * 32, 14, 26, 7),
                new Color(226, 226, 236));
    }
}
