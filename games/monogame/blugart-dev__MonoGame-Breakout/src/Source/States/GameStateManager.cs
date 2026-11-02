using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// Holds the one active state and the session it operates on. Note how small
/// a "screen changer" really is: ChangeState is a field assignment plus an
/// Enter() call, and "new game" is just constructing a fresh GameSession.
/// </summary>
public sealed class GameStateManager
{
    public GameSession Session { get; private set; }
    public SpriteFont Font { get; }

    /// <summary>The last *finished* run, watchable from the game-over screen.</summary>
    public Replay LastReplay { get; private set; }

    /// <summary>True while a replay drives the simulation instead of the player.</summary>
    public bool IsPlayingBack { get; private set; }

    private GameState _current;
    private Replay _recording; // the run in progress; promoted to LastReplay at game over
    private int _playbackIndex;
    private float _replayBannerTimer;

    public GameStateManager(SpriteFont font)
    {
        Font = font;

        // A session exists even under the title screen: the shell reads
        // Session.Shake every Draw, and the debug overlay reads its counts.
        // The title state simply never draws or updates the world.
        Session = new GameSession(GameMode.Modern);
        ChangeState(new TitleState(this));
    }

    public void StartNewGame(GameMode mode, int startLevel = 0)
    {
        Session = new GameSession(mode, startLevel);
        IsPlayingBack = false;
        // Recording costs nothing the player can feel (a few bytes per tick),
        // so every run records unconditionally — there is no "start recording"
        // button anywhere, just as no arcade machine ever asked.
        _recording = new Replay(mode, startLevel, Session.Seed);
        ChangeState(CreateServeState());
    }

    /// <summary>
    /// Re-run the last finished game from its recording: rebuild the session
    /// from the same mode, level and seed, enter the same serve state, and
    /// from here Update feeds the recorded frames instead of live input. No
    /// rewind machinery exists — a replay IS a new run that happens to make
    /// every choice the old one made.
    /// </summary>
    public void StartPlayback()
    {
        Session = new GameSession(LastReplay.Mode, LastReplay.StartLevel, LastReplay.Seed);
        _recording = null;
        _playbackIndex = 0;
        IsPlayingBack = true;
        ChangeState(CreateServeState());
    }

    /// <summary>Same mode, same starting level — the "play again" path.</summary>
    public void RestartCurrentGame()
        => StartNewGame(Session.Mode, Session.StartLevelIndex);

    public void GoToTitle() => ChangeState(new TitleState(this));

    /// <summary>
    /// The one place that maps a mode to its rule-set states. Every "back to
    /// the serve" transition (life lost, new game) routes through here, so
    /// adding a mode never means hunting down transitions.
    /// </summary>
    public GameState CreateServeState()
        => Session.Mode == GameMode.Classic ? new ClassicReadyState(this)
            : Session.IsSuper ? new SuperReadyState(this)
            : new ReadyState(this);

    public void ChangeState(GameState next)
    {
        _current = next;
        next.Enter();

        // Game over ends both kinds of run. A live recording is promoted to
        // "the last replay" only here — abandoning a run to the title screen
        // discards it, because half a movie replays into a desync. Order
        // matters: GameOverState.Enter just read IsPlayingBack (to skip the
        // high-score submit), so the flag flips after Enter, not before.
        if (next is GameOverState)
        {
            if (IsPlayingBack)
            {
                IsPlayingBack = false; // the movie ended where the run did
            }
            else if (_recording != null)
            {
                LastReplay = _recording;
                _recording = null;
            }
        }
    }

    /// <summary>
    /// Make a previously interrupted state current again *without* calling
    /// Enter() — it never conceptually exited, so its one-shot setup (sounds,
    /// re-attaching the ball) must not run a second time.
    /// </summary>
    public void ResumeState(GameState state) => _current = state;

    /// <summary>
    /// Called by the shell when the window loses focus. Auto-pausing the live
    /// game is the professional default — nobody wants to lose a ball while
    /// alt-tabbed. "Live" is exactly IsSimulation: the same bit the replay
    /// system uses to mean "this state is part of the run", so new modes get
    /// auto-pause for free instead of joining a type list here.
    /// </summary>
    public void NotifyFocusLost()
    {
        if (_current.IsSimulation)
            ChangeState(new PauseState(this, _current));
    }

    public bool CurrentCapturesAllInput => _current.CapturesAllInput;

    public void Update(float dt, InputHelper input)
    {
        if (IsPlayingBack)
        {
            _replayBannerTimer += dt;

            // T stops the movie. TitleScreen is not a recorded action, so
            // this read is guaranteed to be live hardware, never the tape.
            if (input.WasActionJustPressed(GameAction.TitleScreen))
            {
                IsPlayingBack = false;
                GoToTitle();
                return;
            }

            if (_current.IsSimulation)
            {
                if (_playbackIndex >= LastReplay.Frames.Count)
                {
                    // Safety net: a complete recording ends at game over and
                    // never reaches here; a truncated one just stops politely.
                    IsPlayingBack = false;
                    GoToTitle();
                    return;
                }
                input.SetPlaybackFrame(LastReplay.Frames[_playbackIndex++]);
            }
            // Not a simulation tick (the viewer paused the movie): no frame is
            // armed, so the pause menu reads live input — and no frame is
            // *consumed*, so the tape and the run stay tick-for-tick aligned.
        }
        else if (_recording != null && _current.IsSimulation)
        {
            _recording.Frames.Add(InputSnapshot.Capture(input));
        }

        if (!_current.FreezesEffects)
            Session.UpdateEffects(dt); // effects run in (almost) every state

        GameState before = _current;
        _current.Update(dt, input);

        // The pause-entry correction. A simulation state that sees the pause
        // press changes state and returns WITHOUT simulating — so the tick we
        // just spent on the tape (recorded above, or consumed from it) never
        // actually happened in the world. Left alone, that off-by-one tick is
        // a replay desync: the recorder banks a frame its run never simulated,
        // and on playback that frame simulates anyway, putting the movie one
        // tick ahead of the original from the pause onward (the viewer pausing
        // has the mirror effect — a consumed frame that never ran). Un-spend
        // it, and "pause ticks are not part of the run" is true on both sides.
        if (before.IsSimulation && _current is PauseState)
        {
            if (IsPlayingBack)
                _playbackIndex--;
            else
                _recording?.Frames.RemoveAt(_recording.Frames.Count - 1);
        }
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        _current.Draw(spriteBatch);

        // The movie must announce itself — a perfect reproduction of play is,
        // by definition, indistinguishable from play. 1 Hz arcade-style blink.
        // The banner is also where the viewer learns the movie controls: both
        // are live (unrecorded) actions, so they work mid-playback by design.
        // Bottom-RIGHT corner, below the paddle line: centered at the bottom
        // it blinked directly on top of the paddle — the one thing a replay
        // viewer is watching — and collided with the debug overlay's
        // bottom-left readout.
        if (IsPlayingBack && (int)(_replayBannerTimer * 2f) % 2 == 0)
        {
            const string banner = "REPLAY - T STOP / P PAUSE";
            const float scale = 0.75f;
            float width = Font.MeasureString(banner).X * scale;
            spriteBatch.DrawShadowedText(Font, banner,
                new Vector2(Screen.Width - 12 - width, Screen.Height - 26),
                Color.Gold, scale);
        }
    }
}
