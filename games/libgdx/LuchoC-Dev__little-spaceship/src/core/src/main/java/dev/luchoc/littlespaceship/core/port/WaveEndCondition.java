package dev.luchoc.littlespaceship.core.port;

/**
 * What ends a {@link WaveDefinition}, chosen per wave — decided by the project owner on 27/08/2026,
 * recorded in {@code docs/planning/08-decisions-and-open-items.md}, "The 11 group, 27/08/2026".
 *
 * <p>{@link FixedDuration} is the default: unless a wave says otherwise, it ends after a fixed number
 * of seconds regardless of what is still alive, the same way {@code SpawnSystem}'s single cursor
 * already behaves today. {@link Cleared} ends a wave once every entity it spawned is gone — destroyed
 * or off the playfield — which only means something once an entity can record which wave spawned it
 * and can be removed for leaving the playfield: issues #85 and #84.
 *
 * <p>Sealed to exactly these two so the system that resolves a wave's end (issue #112) can switch on
 * which one it is without a third, unnamed case ever compiling — the same reason invariant 6 keeps a
 * wave from taking parameters: nothing in the 11 group needs a third kind of ending yet.
 */
public sealed interface WaveEndCondition {

    /**
     * Ends the wave a fixed number of seconds after it starts, independent of what is still on
     * screen.
     *
     * @param seconds how long the wave lasts; must be a positive, finite number of seconds
     */
    record FixedDuration(float seconds) implements WaveEndCondition {

        public FixedDuration {
            if (seconds <= 0f || Float.isNaN(seconds) || Float.isInfinite(seconds)) {
                throw new IllegalArgumentException(
                    "a fixed wave duration must be a positive, finite number of seconds, was "
                        + seconds);
            }
        }
    }

    /**
     * Ends the wave once every entity it spawned has been destroyed or has left the playfield.
     * Carries no data: the condition is answered entirely by asking {@code World} which entities
     * still exist, not by a number declared here.
     */
    record Cleared() implements WaveEndCondition {
    }
}
