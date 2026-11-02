using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Breakout.States;
using Breakout.Systems;

namespace Breakout;

/// <summary>
/// The application shell (named BreakoutGame, not the template's "Game1" —
/// that default is a placeholder, not a name). Deliberately
/// thin: owns the window, the loop, the SpriteBatch and the virtual screen,
/// and delegates everything else to the GameStateManager. All gameplay lives
/// under /Source and thinks exclusively in 800x480 virtual coordinates —
/// window size, fullscreen and letterboxing are handled here and in
/// VirtualScreen, nowhere else.
/// </summary>
public class BreakoutGame : Game
{
    // Near-black, slightly blue so "true black" elements still read against it.
    private static readonly Color ClearColor = new(10, 10, 16);

    private readonly GraphicsDeviceManager _graphics;
    private readonly InputHelper _input = new();
    private readonly DebugOverlay _debugOverlay = new();

    private SpriteBatch _spriteBatch;
    private VirtualScreen _virtualScreen;
    private GameStateManager _states;
    private SpriteFont _font;

    private bool _showDebugOverlay;
    private Point _windowedSize = new(Screen.Width, Screen.Height);
    private bool _isResizing; // re-entrancy guard: ApplyChanges() re-fires ClientSizeChanged

    private readonly ScreenshotRig _screenshotRig; // null on a normal run

    public BreakoutGame(ScreenshotRig screenshotRig = null)
    {
        _screenshotRig = screenshotRig;
        _graphics = new GraphicsDeviceManager(this);

        // In the constructor the GraphicsDevice doesn't exist yet, so these are
        // "preferences" the device is created with. Changing them later (see
        // ToggleFullscreen below) requires _graphics.ApplyChanges().
        _graphics.PreferredBackBufferWidth = Screen.Width;
        _graphics.PreferredBackBufferHeight = Screen.Height;

        Window.Title = "Breakout";
        Window.AllowUserResizing = true;
        // DesktopGL does not resize the back buffer when the window is resized;
        // do it ourselves so 1 back-buffer pixel == 1 window pixel stays true
        // (VirtualScreen's letterbox and mouse math both depend on it).
        Window.ClientSizeChanged += OnClientSizeChanged;

        Content.RootDirectory = "Content";
        IsMouseVisible = true;

        // MonoGame default, stated explicitly on purpose: Update() runs on a
        // fixed 60 Hz clock ("fixed timestep"), so the simulation ticks at a
        // steady, predictable rate no matter how fast the machine renders.
        // Movement still multiplies by elapsed time so gameplay code never
        // assumes the rate — see the study guide (docs/index.html) §02 for
        // why you want both.
        IsFixedTimeStep = true;
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _virtualScreen = new VirtualScreen(GraphicsDevice, Screen.Width, Screen.Height);
        SpriteBatchExtensions.Initialize(GraphicsDevice);
        AudioBank.Initialize();

        // Music loops from the first frame and never stops: states *duck* it
        // (pause, game over) and M mutes it, but nobody re-Plays it — one
        // long-lived SoundEffectInstance instead of per-screen track juggling.
        MusicPlayer.Initialize();
        MusicPlayer.Play();

        // Pipeline asset names are path-without-extension relative to Content/.
        _font = Content.Load<SpriteFont>("Fonts/Hud");

        // The CRT shader is the pipeline's other asset type: .fx source went
        // in, a compiled Effect comes out — same path-without-extension rule.
        _virtualScreen.SetCrtEffect(Content.Load<Effect>("Shaders/Crt"));

        _states = new GameStateManager(_font);

        // A screenshot run skips the title screen and boots straight into the
        // requested mode's serve screen (null mode = stay on the title).
        if (_screenshotRig?.Mode is GameMode mode)
            _states.StartNewGame(mode);
    }

    protected override void Update(GameTime gameTime)
    {
        // Pause the simulation while the window is unfocused — MonoGame keeps
        // calling Update regardless, and nobody wants to lose a ball while
        // alt-tabbed. base.Update still runs for framework housekeeping.
        // A screenshot run skips the gate: launched from a terminal, the
        // window may never receive focus, and a paused world can't settle.
        if (!IsActive && _screenshotRig == null)
        {
            _states.NotifyFocusLost(); // a live game auto-pauses, see PauseState
            base.Update(gameTime);
            return;
        }

        _input.Update(_virtualScreen);

        // The rebind screen captures all input: while it is waiting for "any
        // key", none of these shortcuts may steal the press.
        if (!_states.CurrentCapturesAllInput)
        {
            // Just-pressed, not held: Esc also cancels a rebind wait, and a
            // human still holds the key on the tick after the capture drops —
            // a level-triggered quit here would close the game on that tick.
            if (_input.WasActionJustPressed(GameAction.Quit))
                Exit();
            if (_input.WasActionJustPressed(GameAction.ToggleFullscreen))
                ToggleFullscreen();
            if (_input.WasActionJustPressed(GameAction.ToggleDebugOverlay))
                _showDebugOverlay = !_showDebugOverlay;
            if (_input.WasActionJustPressed(GameAction.ToggleIntegerScaling))
                _virtualScreen.IntegerScaling = !_virtualScreen.IntegerScaling;
            if (_input.WasActionJustPressed(GameAction.ToggleCrt))
                _virtualScreen.CrtEnabled = !_virtualScreen.CrtEnabled;
            if (_input.WasActionJustPressed(GameAction.ToggleMusic))
                MusicPlayer.ToggleMuted();
        }

        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        _states.Update(dt, _input);

        _screenshotRig?.Tick();

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        _debugOverlay.CountFrame((float)gameTime.ElapsedGameTime.TotalSeconds);

        // Pass 1: the whole game, into the 800x480 render target.
        _virtualScreen.BeginDraw();
        GraphicsDevice.Clear(ClearColor);

        _spriteBatch.Begin(
            samplerState: SamplerState.PointClamp,
            transformMatrix: _states.Session.Shake.TransformMatrix);
        _states.Draw(_spriteBatch);
        if (_showDebugOverlay)
            _debugOverlay.Draw(_spriteBatch, _font, _states.Session);
        _spriteBatch.End();

        // Pass 2: the render target onto the real back buffer, letterboxed.
        _virtualScreen.Present(_spriteBatch);

        // After Present, so the CRT pass is in the captured pixels.
        if (_screenshotRig?.CaptureDue == true)
        {
            _screenshotRig.Capture(GraphicsDevice);
            Exit();
        }

        base.Draw(gameTime);
    }

    private void ToggleFullscreen()
    {
        if (_graphics.IsFullScreen)
        {
            _graphics.IsFullScreen = false;
            _graphics.PreferredBackBufferWidth = _windowedSize.X;
            _graphics.PreferredBackBufferHeight = _windowedSize.Y;
        }
        else
        {
            _windowedSize = new Point(Window.ClientBounds.Width, Window.ClientBounds.Height);

            // Borderless fullscreen: keep the desktop resolution and skip the
            // hardware mode switch — instant, flicker-free, alt-tab friendly.
            // Exclusive mode (HardwareModeSwitch = true) only earns its pain
            // when you need every last millisecond of latency.
            _graphics.HardwareModeSwitch = false;
            DisplayMode display = GraphicsDevice.Adapter.CurrentDisplayMode;
            _graphics.PreferredBackBufferWidth = display.Width;
            _graphics.PreferredBackBufferHeight = display.Height;
            _graphics.IsFullScreen = true;
        }

        _graphics.ApplyChanges(); // device exists now — this is the case that needs it
    }

    private void OnClientSizeChanged(object sender, EventArgs e)
    {
        if (_isResizing || Window.ClientBounds.Width == 0 || Window.ClientBounds.Height == 0)
            return;

        _isResizing = true;
        _graphics.PreferredBackBufferWidth = Window.ClientBounds.Width;
        _graphics.PreferredBackBufferHeight = Window.ClientBounds.Height;
        _graphics.ApplyChanges();
        _isResizing = false;
    }
}
