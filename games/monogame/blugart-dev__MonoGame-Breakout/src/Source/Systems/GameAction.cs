namespace Breakout.Systems;

/// <summary>
/// Every input the game responds to, named by intent rather than by key.
/// Gameplay code asks "is MoveLeft down?" and never mentions a keyboard —
/// which key (or keys) that means is ActionMap's business alone.
/// </summary>
public enum GameAction
{
    MoveLeft,
    MoveRight,
    Launch,
    Pause,
    Restart,
    MenuUp,
    MenuDown,
    TitleScreen,
    OpenRebind,
    P1MoveLeft,
    P1MoveRight,
    P2MoveLeft,
    P2MoveRight,
    WatchReplay,
    ToggleFullscreen,
    ToggleDebugOverlay,
    ToggleIntegerScaling,
    ToggleCrt,
    ToggleMusic,
    Quit,
}
