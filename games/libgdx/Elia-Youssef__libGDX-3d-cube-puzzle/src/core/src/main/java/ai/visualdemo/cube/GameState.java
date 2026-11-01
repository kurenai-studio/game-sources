package ai.visualdemo.cube;

/**
 * The puzzle's high-level state. PLAYING is the only state where the player's input changes
 * anything; every other state is a frozen moment that only R can escape.
 */
public enum GameState {
    /** Both pieces are suspended and rotatable; the timer is counting down. */
    PLAYING,
    /** Both pieces just matched and are sliding together into the completed cube. */
    ASSEMBLING,
    /** The join animation finished; the completed cube and "You Win" are shown. */
    WON,
    /** The timer hit zero before the pieces matched; "You Lose" is shown. */
    LOST
}
