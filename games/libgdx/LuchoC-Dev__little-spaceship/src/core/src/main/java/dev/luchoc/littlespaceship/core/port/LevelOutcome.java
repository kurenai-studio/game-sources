package dev.luchoc.littlespaceship.core.port;

/**
 * Whether the current run is still going, and how it ended if it is not — the signal {@code game}
 * needs to reach the Victory and Defeat screens instead of a debug key.
 *
 * <p>{@code 02-mvp-functional-spec.md} names victory as defeating the boss with at least one life
 * left, but the boss is phase 07's: nothing in the MVP shipped so far can honestly claim that. {@link
 * #COMPLETED} is deliberately not called {@code VICTORY} for that reason — it reports the only thing
 * a level can honestly finish on today, the wave timeline running dry with no enemy left standing
 * and at least one life remaining. Phase 07 is expected to fold a real boss-defeat condition into
 * this same value once it exists, rather than adding a second, competing signal.
 *
 * <p>{@link #DEFEATED} needs no such caveat: {@code DamageSystem} already enforces "a life is never
 * taken below zero", so losing the run is exactly {@code Player.lives} reaching zero, decided today
 * exactly as {@code 02-mvp-functional-spec.md} states it.
 */
public enum LevelOutcome {

    /** The run is still going: neither condition below has been reached yet. */
    IN_PROGRESS,

    /**
     * The wave timeline has run out of events, no entity carries an {@code ENEMY} collider anymore,
     * and the player has at least one life left. See the class javadoc for why this is not called
     * {@code VICTORY}.
     */
    COMPLETED,

    /** The player has lost every life. */
    DEFEATED
}
