package com.tomer.scoundrel.model;

/** Whether the game is still running or how it ended. */
public enum Status {
    /** Still being played: there are legal moves, and no score yet. */
    IN_PROGRESS,
    /** The dungeon and the last room were cleared with health above zero. */
    WON,
    /** Health reached zero or below; the state is frozen as it stood at that move. */
    LOST
}
