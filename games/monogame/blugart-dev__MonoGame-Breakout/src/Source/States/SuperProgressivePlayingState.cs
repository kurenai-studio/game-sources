using Breakout.Entities;
using Breakout.Systems;

namespace Breakout.States;

/// <summary>
/// PROGRESSIVE: no wall to clear — an endless conveyor of walls creeping
/// toward the paddle, four rows of bricks then four of blanks, forever. A
/// brick's value is its *position*: the screen is four fixed color zones
/// (blue 7, orange 5, green 3, yellow 1), every scroll step re-prices the
/// whole wall, and bricks that reach the bottom simply leave, "not counted
/// toward or against the player's score". Greed is the entire game: bore
/// into the back rows while they are blue, or farm cheap yellow safety while
/// the wall closes in. The manual calls the maximum score "infinite".
/// </summary>
public sealed class SuperProgressivePlayingState : SuperPlayingState
{
    // The scroll is hit-driven, not time-driven ("a rate determined by the
    // number of hits on the ball"), and it accelerates. The exact curve is
    // undocumented; observed on the cabinet: one row every other return at
    // first, then every return.
    private const int RowEveryNthReturn = 2;
    private const int FastAfterReturns = 16;

    private int _returns;

    public SuperProgressivePlayingState(GameStateManager manager) : base(manager) { }

    protected override void OnPaddleHit(Ball ball)
    {
        _returns++;
        if (_returns >= FastAfterReturns || _returns % RowEveryNthReturn == 0)
            SuperWall.ScrollProgressive(Session.Bricks, ref Session.ProgressiveRowPhase,
                Session.Balls); // the scroll must not land a brick on the ball
    }

    /// <summary>
    /// "When the ball is missed and served again, the row of bricks closest
    /// to the paddle disappears as the entire picture scrolls down one row."
    /// The miss is the event, so the penalty lives here — not in the ready
    /// state guessing "was that a re-serve?" from the lives counter.
    /// </summary>
    protected override void OnBallLost(Ball ball)
        => SuperWall.ScrollProgressive(Session.Bricks, ref Session.ProgressiveRowPhase,
            Session.Balls); // empty by now — the lost ball was the only one
}
