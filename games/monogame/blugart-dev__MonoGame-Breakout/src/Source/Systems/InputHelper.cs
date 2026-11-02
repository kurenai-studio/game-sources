using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace Breakout.Systems;

/// <summary>
/// MonoGame input is pure polling: Keyboard.GetState() returns a snapshot of
/// what is held down *right now* — there are no events and no action map.
/// "Was this key *just* pressed?" therefore requires memory: keep last frame's
/// snapshot and compare. Engines that offer a built-in "just pressed" query
/// are doing exactly this comparison under the hood; here it is two lines you
/// can read. The ActionMap (exposed as Actions) adds the second layer engines
/// bundle: naming inputs by intent so gameplay never mentions a key.
/// </summary>
public sealed class InputHelper
{
    /// <summary>Key bindings; gameplay reads input via actions, not Keys.</summary>
    public ActionMap Actions { get; } = new();

    private KeyboardState _keyboard, _previousKeyboard;
    private MouseState _mouse, _previousMouse;
    private GamePadState _gamePad, _previousGamePad;
    private Point _virtualMousePosition;

    // Replay playback: when the state manager arms a recorded frame for this
    // tick, the *recorded* gameplay actions and the mouse answer from it
    // instead of the hardware. Everything unrecorded (pause, menus, shell
    // shortcuts) still reads live — the viewer keeps control of the player
    // while the recording controls the paddle.
    private InputSnapshot? _playbackFrame;

    /// <summary>Arm one recorded frame for this tick (playback only).</summary>
    public void SetPlaybackFrame(InputSnapshot frame) => _playbackFrame = frame;

    /// <summary>Call exactly once per Update tick, before anything reads input.</summary>
    public void Update(VirtualScreen virtualScreen)
    {
        // Every tick starts live; the manager re-arms a playback frame each
        // simulation tick it feeds, so a frame can never leak across ticks.
        _playbackFrame = null;

        _previousKeyboard = _keyboard;
        _previousMouse = _mouse;
        _previousGamePad = _gamePad;
        _keyboard = Keyboard.GetState();
        _mouse = Mouse.GetState();

        // Same polling model as the keyboard. With no pad plugged in this
        // returns a disconnected state whose buttons all read "up" — cheap
        // and safe, so we don't bother checking IsConnected every frame.
        _gamePad = GamePad.GetState(PlayerIndex.One);

        // The OS reports the mouse in window-client pixels; the game thinks in
        // virtual pixels. Convert once here so no gameplay code ever knows the
        // window size exists.
        _virtualMousePosition = virtualScreen.WindowToVirtual(new Point(_mouse.X, _mouse.Y));
    }

    // The action-level queries: any bound key OR gamepad button satisfies the
    // action. These loop over arrays instead of allocating LINQ enumerators
    // because they run every tick on the hot path. Note that gameplay code
    // calling these never learned a gamepad exists — that is the action
    // layer's whole promise.

    public bool IsActionDown(GameAction action)
    {
        if (_playbackFrame is { } frame && InputSnapshot.IsRecorded(action))
            return frame.IsActionDown(action);

        IReadOnlyList<Keys> keys = Actions.KeysFor(action);
        for (int i = 0; i < keys.Count; i++)
            if (_keyboard.IsKeyDown(keys[i]))
                return true;

        IReadOnlyList<Buttons> buttons = Actions.ButtonsFor(action);
        for (int i = 0; i < buttons.Count; i++)
            if (_gamePad.IsButtonDown(buttons[i]))
                return true;

        return false;
    }

    public bool WasActionJustPressed(GameAction action)
    {
        if (_playbackFrame is { } frame && InputSnapshot.IsRecorded(action))
            return frame.WasActionJustPressed(action);

        IReadOnlyList<Keys> keys = Actions.KeysFor(action);
        for (int i = 0; i < keys.Count; i++)
            if (_keyboard.IsKeyDown(keys[i]) && _previousKeyboard.IsKeyUp(keys[i]))
                return true;

        IReadOnlyList<Buttons> buttons = Actions.ButtonsFor(action);
        for (int i = 0; i < buttons.Count; i++)
            if (_gamePad.IsButtonDown(buttons[i]) && _previousGamePad.IsButtonUp(buttons[i]))
                return true;

        return false;
    }

    /// <summary>
    /// The rebind poll: the first key that went down *this frame*, or null.
    /// "Which key did the player just press?" has no direct API — you diff
    /// the full pressed-key sets between frames. GetPressedKeys() allocates
    /// an array per call, which is why this is a method the rebind screen
    /// calls and not something Update computes every tick for everyone.
    /// </summary>
    public Keys? FirstNewKey()
    {
        foreach (Keys key in _keyboard.GetPressedKeys())
            if (_previousKeyboard.IsKeyUp(key))
                return key;
        return null;
    }

    // The mouse queries defer to an armed playback frame wholesale: unlike
    // actions there is no live/recorded split to honor — only the simulation
    // reads the mouse, and during playback the simulation IS the recording.

    public bool WasLeftClickJustPressed
        => _playbackFrame is { } frame
            ? frame.LeftClickJustPressed
            : _mouse.LeftButton == ButtonState.Pressed
              && _previousMouse.LeftButton == ButtonState.Released;

    /// <summary>Mouse X in virtual (800x480) coordinates.</summary>
    public int MouseX
        => _playbackFrame is { } frame ? frame.MouseX : _virtualMousePosition.X;

    // Movement detection compares *raw* positions: the virtual transform
    // rounds to ints, and that rounding could register phantom movement.
    public bool MouseMoved
        => _playbackFrame is { } frame
            ? frame.MouseMoved
            : _mouse.X != _previousMouse.X || _mouse.Y != _previousMouse.Y;
}
