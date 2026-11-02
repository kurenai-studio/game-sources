using Breakout.Systems;
using Xunit;

namespace Breakout.Tests;

/// <summary>
/// The replay system's correctness rests on a contract: gameplay actions are
/// on the tape, everything else stays live. The contract is data (a set), so
/// the test enumerates the whole enum and asserts each member's side — if a
/// future action lands on the wrong side, this fails with its name.
/// </summary>
public class InputSnapshotTests
{
    [Theory]
    [InlineData(GameAction.MoveLeft)]
    [InlineData(GameAction.MoveRight)]
    [InlineData(GameAction.Launch)]
    [InlineData(GameAction.P1MoveLeft)]
    [InlineData(GameAction.P1MoveRight)]
    [InlineData(GameAction.P2MoveLeft)]
    [InlineData(GameAction.P2MoveRight)]
    public void GameplayActionsAreRecorded(GameAction action)
        => Assert.True(InputSnapshot.IsRecorded(action));

    [Theory]
    [InlineData(GameAction.Pause)]        // the viewer must be able to pause the movie
    [InlineData(GameAction.Restart)]
    [InlineData(GameAction.MenuUp)]
    [InlineData(GameAction.MenuDown)]
    [InlineData(GameAction.TitleScreen)]  // T is the live stop-the-replay control
    [InlineData(GameAction.OpenRebind)]
    [InlineData(GameAction.WatchReplay)]
    [InlineData(GameAction.ToggleFullscreen)]
    [InlineData(GameAction.ToggleDebugOverlay)]
    [InlineData(GameAction.ToggleIntegerScaling)]
    [InlineData(GameAction.ToggleCrt)]
    [InlineData(GameAction.ToggleMusic)]
    [InlineData(GameAction.Quit)]         // a recorded Quit would close the app mid-replay
    public void ShellAndMenuActionsStayLive(GameAction action)
        => Assert.False(InputSnapshot.IsRecorded(action));
}
