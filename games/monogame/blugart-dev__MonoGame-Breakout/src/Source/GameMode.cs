namespace Breakout;

/// <summary>
/// Which rule set a session runs under. The entities (paddle, ball, bricks)
/// are shared and dumb; the rules live in the states, so a mode is simply
/// "which state objects drive the session" — Modern uses ReadyState /
/// PlayingState, Classic uses ClassicReadyState / ClassicPlayingState.
/// </summary>
public enum GameMode
{
    /// <summary>The house rules: 3 tiered boards, power-ups, multiball.</summary>
    Modern,

    /// <summary>
    /// Modern rules with two paddles, each guarding half the court with its
    /// own action set. Note it reuses ReadyState/PlayingState unchanged —
    /// they iterate Session.Paddles, so "how many paddles" is session data,
    /// not a rule difference.
    /// </summary>
    Coop,

    /// <summary>
    /// The 1976 Atari arcade rules, reconstructed from the original operation
    /// manual: an 8x14 one-hit wall scored 1/1/3/3/5/5/7/7 by row, four
    /// discrete ball speeds, a paddle that halves after a breakout, one brick
    /// per trip, and exactly two walls for a 896-point maximum.
    /// </summary>
    Classic,

    // The three Super Breakout (1978) games, from the sequel's operation
    // manual. They share SuperReadyState and the SuperPlayingState physics
    // (five speeds, pass-through rule, shrink on top contact, score times
    // balls in play); each gets one playing-state subclass for what differs.

    /// <summary>
    /// Super Breakout "Double": two stacked paddles on one set of controls,
    /// two balls per serve, double points while both balls fly.
    /// </summary>
    SuperDouble,

    /// <summary>
    /// Super Breakout "Cavity": two captive balls sealed inside the wall;
    /// freeing them puts up to three balls in play for x2/x3 scoring.
    /// </summary>
    SuperCavity,

    /// <summary>
    /// Super Breakout "Progressive": an endless wall that scrolls toward the
    /// paddle, with brick values priced by screen position.
    /// </summary>
    SuperProgressive,
}
