package com.micro1.territory;

/** The game's high-level states. Exactly one is active at a time. */
public enum GamePhase {
    START,      // title + empty rectangle, waiting for S
    COUNTDOWN,  // 3s countdown, partitioned rectangle hidden
    SELECT,     // 3s selection, partitioned rectangle revealed
    RESULT,     // largest highlighted + leaderboard, waiting for N
    FINAL       // final rankings, winners/losers
}
