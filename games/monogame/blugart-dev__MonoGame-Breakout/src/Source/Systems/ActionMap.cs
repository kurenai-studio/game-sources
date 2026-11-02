using System.Collections.Generic;
using Microsoft.Xna.Framework.Input;

namespace Breakout.Systems;

/// <summary>
/// The input-mapping layer big engines ship built in, rebuilt as one
/// dictionary per device: action → the keys (or gamepad buttons) currently
/// bound to it. Two things fall out for free. Alternate bindings are just
/// more entries in the array (arrows AND A/D both mean "move"), and rebinding
/// at runtime is a dictionary write — no gameplay code changes, because no
/// gameplay code names a key. Adding the gamepad proved the layer's worth:
/// it is one more dictionary here and two loops in InputHelper, and not a
/// single gameplay file changed. Mouse input deliberately stays outside the
/// map: it is positional, not a binary "pressed" thing a Keys value could
/// stand in for.
/// </summary>
public sealed class ActionMap
{
    private readonly Dictionary<GameAction, Keys[]> _bindings = new()
    {
        [GameAction.MoveLeft] = new[] { Keys.Left, Keys.A },
        [GameAction.MoveRight] = new[] { Keys.Right, Keys.D },
        [GameAction.Launch] = new[] { Keys.Space },
        [GameAction.Pause] = new[] { Keys.P },
        [GameAction.Restart] = new[] { Keys.Enter },
        [GameAction.MenuUp] = new[] { Keys.Up, Keys.W },
        [GameAction.MenuDown] = new[] { Keys.Down, Keys.S },
        [GameAction.TitleScreen] = new[] { Keys.T },
        [GameAction.OpenRebind] = new[] { Keys.B },
        // Co-op splits what single-player merges: MoveLeft means "arrows OR
        // A/D", but with two players those have to be two different intents.
        [GameAction.P1MoveLeft] = new[] { Keys.A },
        [GameAction.P1MoveRight] = new[] { Keys.D },
        [GameAction.P2MoveLeft] = new[] { Keys.Left },
        [GameAction.P2MoveRight] = new[] { Keys.Right },
        [GameAction.WatchReplay] = new[] { Keys.R },
        [GameAction.ToggleFullscreen] = new[] { Keys.F11 },
        [GameAction.ToggleDebugOverlay] = new[] { Keys.F3 },
        [GameAction.ToggleIntegerScaling] = new[] { Keys.F10 },
        [GameAction.ToggleCrt] = new[] { Keys.F9 },
        [GameAction.ToggleMusic] = new[] { Keys.M },
        [GameAction.Quit] = new[] { Keys.Escape },
    };

    // The gamepad half of the map. MonoGame exposes thumbstick directions as
    // pseudo-buttons (LeftThumbstickLeft etc., with a built-in dead zone), so
    // analog movement joins the same binary action model for free. Not every
    // action needs a pad binding — F-key toggles stay keyboard-only.
    private readonly Dictionary<GameAction, Buttons[]> _buttonBindings = new()
    {
        [GameAction.MoveLeft] = new[] { Buttons.DPadLeft, Buttons.LeftThumbstickLeft },
        [GameAction.MoveRight] = new[] { Buttons.DPadRight, Buttons.LeftThumbstickRight },
        [GameAction.Launch] = new[] { Buttons.A },
        [GameAction.Pause] = new[] { Buttons.Start },
        [GameAction.Restart] = new[] { Buttons.A, Buttons.Start },
        [GameAction.MenuUp] = new[] { Buttons.DPadUp, Buttons.LeftThumbstickUp },
        [GameAction.MenuDown] = new[] { Buttons.DPadDown, Buttons.LeftThumbstickDown },
        [GameAction.TitleScreen] = new[] { Buttons.Y },
        [GameAction.WatchReplay] = new[] { Buttons.X },
        [GameAction.Quit] = new[] { Buttons.Back },
        // In co-op the gamepad player drives paddle two.
        [GameAction.P2MoveLeft] = new[] { Buttons.DPadLeft, Buttons.LeftThumbstickLeft },
        [GameAction.P2MoveRight] = new[] { Buttons.DPadRight, Buttons.LeftThumbstickRight },
    };

    private static readonly Buttons[] NoButtons = System.Array.Empty<Buttons>();

    public IReadOnlyList<Keys> KeysFor(GameAction action) => _bindings[action];

    public IReadOnlyList<Buttons> ButtonsFor(GameAction action)
        => _buttonBindings.TryGetValue(action, out Buttons[] buttons) ? buttons : NoButtons;

    /// <summary>
    /// Replace an action's bindings at runtime. This dictionary write is the
    /// entire rebinding mechanism — a settings screen would collect the new
    /// key (poll for "any key just pressed") and call this.
    /// </summary>
    public void Rebind(GameAction action, params Keys[] keys)
        => _bindings[action] = keys;
}
