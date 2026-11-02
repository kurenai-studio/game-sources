using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// Runtime key rebinding, reached from pause. The mechanism is tiny because
/// the action map already did the hard part: collecting a new key is
/// InputHelper.FirstNewKey (diff the pressed-key sets between frames — there
/// is no "which key was that?" API), and applying it is one ActionMap.Rebind
/// call. While waiting for a key this state raises CapturesAllInput so the
/// shell's global shortcuts (Esc, F11, M…) can't steal the press; Esc cancels
/// the wait instead of quitting the game. Bindings are session-lifetime —
/// persisting them to disk would follow the HighScores pattern.
/// </summary>
public sealed class RebindState : GameState
{
    private static readonly (GameAction Action, string Label)[] Rows =
    {
        (GameAction.MoveLeft, "MOVE LEFT"),
        (GameAction.MoveRight, "MOVE RIGHT"),
        (GameAction.Launch, "LAUNCH / SERVE"),
        (GameAction.Pause, "PAUSE"),
        (GameAction.Restart, "RESTART"),
    };

    private static readonly Color DimColor = new(150, 150, 165);

    private readonly GameState _resumeTo; // the PauseState that opened us
    private readonly ActionMap _actions;  // Draw shows bindings; Update has no monopoly on them
    private int _selected;
    private bool _waitingForKey;

    public RebindState(GameStateManager manager, GameState resumeTo, ActionMap actions)
        : base(manager)
    {
        _resumeTo = resumeTo;
        _actions = actions;
    }

    public override bool FreezesEffects => true; // still conceptually paused

    public override bool CapturesAllInput => _waitingForKey;

    public override void Update(float dt, InputHelper input)
    {
        if (_waitingForKey)
        {
            Keys? key = input.FirstNewKey();
            if (key == Keys.Escape)
                _waitingForKey = false; // cancel, keep the old binding
            else if (key != null)
            {
                // Rebinding replaces ALL previous bindings for the action —
                // including alternates like arrows+WASD. Deliberate: "the
                // key I just chose" beats silently keeping invisible extras.
                _actions.Rebind(Rows[_selected].Action, key.Value);
                _waitingForKey = false;
            }
            return;
        }

        if (input.WasActionJustPressed(GameAction.MenuUp))
            _selected = (_selected + Rows.Length - 1) % Rows.Length;
        if (input.WasActionJustPressed(GameAction.MenuDown))
            _selected = (_selected + 1) % Rows.Length;

        if (input.WasActionJustPressed(GameAction.Launch)
            || input.WasActionJustPressed(GameAction.Restart))
            _waitingForKey = true;
        else if (input.WasActionJustPressed(GameAction.OpenRebind))
            Manager.ResumeState(_resumeTo); // back to pause, no re-Enter
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        var center = new Vector2(Screen.Width / 2f, 0);

        spriteBatch.DrawCenteredText(Font, "KEY BINDINGS",
            center + new Vector2(0, 80), Color.White, 1.5f);

        for (int i = 0; i < Rows.Length; i++)
        {
            bool selected = i == _selected;
            string detail = selected && _waitingForKey
                ? "PRESS A KEY..."
                : FormatKeys(Rows[i].Action);
            string line = $"{Rows[i].Label}   {detail}";
            if (selected)
                line = $"> {line} <";

            spriteBatch.DrawCenteredText(Font, line,
                center + new Vector2(0, 160 + i * 36),
                selected ? Color.White : DimColor,
                selected ? 1f : 0.85f);
        }

        spriteBatch.DrawCenteredText(Font,
            "UP/DOWN SELECT   SPACE/ENTER REBIND   B BACK",
            center + new Vector2(0, 400), DimColor, 0.75f);
        spriteBatch.DrawCenteredText(Font,
            "ESC CANCELS WHILE WAITING",
            center + new Vector2(0, 430), DimColor, 0.75f);
    }

    private string FormatKeys(GameAction action)
    {
        // Keys.ToString() gives readable names ("Left", "Space", "D") — good
        // enough for a settings screen without a display-name table.
        var keys = _actions.KeysFor(action);
        var names = new string[keys.Count];
        for (int i = 0; i < keys.Count; i++)
            names[i] = keys[i].ToString().ToUpperInvariant();
        return string.Join(" / ", names);
    }
}
