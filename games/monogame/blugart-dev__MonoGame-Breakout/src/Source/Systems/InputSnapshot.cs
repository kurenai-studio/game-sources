namespace Breakout.Systems;

/// <summary>
/// One simulation tick of input, reduced to exactly what the gameplay states
/// consume: the gameplay actions as two bitmasks (down / just-pressed) plus
/// the three mouse facts. This struct is the whole replay format — because
/// the simulation runs on a fixed 60 Hz timestep with a seeded Random, a run
/// is fully determined by its starting conditions plus this sequence, so
/// "record a replay" literally means "keep these in a list".
/// </summary>
public readonly struct InputSnapshot
{
    // Only the actions the simulation reads are recorded. Everything else —
    // Pause, the menus, the shell shortcuts — deliberately stays live during
    // playback: the viewer can still pause, rebind, or quit the *replay*
    // without those presses ever having been part of the *run*.
    private static readonly GameAction[] RecordedActions =
    {
        GameAction.MoveLeft, GameAction.MoveRight, GameAction.Launch,
        GameAction.P1MoveLeft, GameAction.P1MoveRight,
        GameAction.P2MoveLeft, GameAction.P2MoveRight,
    };

    private static readonly uint RecordedMask = BuildRecordedMask();

    // One bit per GameAction, indexed by enum value — 19 actions fit a uint
    // with room to spare. A bool[] would record the same facts in 32x the
    // space; compactness matters when you keep 60 of these per second.
    private readonly uint _down;
    private readonly uint _justPressed;

    public readonly int MouseX;
    public readonly bool MouseMoved;
    public readonly bool LeftClickJustPressed;

    private InputSnapshot(uint down, uint justPressed,
        int mouseX, bool mouseMoved, bool leftClickJustPressed)
    {
        _down = down;
        _justPressed = justPressed;
        MouseX = mouseX;
        MouseMoved = mouseMoved;
        LeftClickJustPressed = leftClickJustPressed;
    }

    /// <summary>Freeze the current tick's live input into a recordable frame.</summary>
    public static InputSnapshot Capture(InputHelper input)
    {
        uint down = 0, justPressed = 0;
        foreach (GameAction action in RecordedActions)
        {
            if (input.IsActionDown(action))
                down |= Bit(action);
            if (input.WasActionJustPressed(action))
                justPressed |= Bit(action);
        }
        return new InputSnapshot(down, justPressed,
            input.MouseX, input.MouseMoved, input.WasLeftClickJustPressed);
    }

    /// <summary>Whether playback answers for this action (else it stays live).</summary>
    public static bool IsRecorded(GameAction action) => (RecordedMask & Bit(action)) != 0;

    public bool IsActionDown(GameAction action) => (_down & Bit(action)) != 0;

    public bool WasActionJustPressed(GameAction action) => (_justPressed & Bit(action)) != 0;

    private static uint Bit(GameAction action) => 1u << (int)action;

    private static uint BuildRecordedMask()
    {
        uint mask = 0;
        foreach (GameAction action in RecordedActions)
            mask |= Bit(action);
        return mask;
    }
}
