package dev.luchoc.littlespaceship.core.domain.component;

/**
 * How much longer an entity is allowed to exist once the level considers it done with, counted down
 * every tick by {@code LifetimeSystem}.
 *
 * <p>This is a safety mechanism, not a balance knob: {@code LifetimeSystem} never removes the entity
 * the instant {@link #remaining} reaches zero. It waits until the entity has also left the playfield,
 * so nothing this component is attached to ever vanishes in front of the player — an enemy still
 * visible when its lifetime expires simply keeps existing until it leaves on its own, or until the
 * safety box catches it. See {@code LifetimeSystem}'s own javadoc for the two-mechanism split this
 * component is one half of.
 *
 * <p>{@link #remaining} is data set from an archetype's own {@code "lifetime"} component spec —
 * {@code {"seconds": N}} — the same call {@code 08-decisions-and-open-items.md} already made for
 * attachment durability: a duration nobody decided is a game rule nobody decided, so it is never a
 * constant in code.
 */
public final class Lifetime {

    /** Seconds left before this entity is eligible for removal, once also off screen. */
    public float remaining;

    /**
     * @param seconds the entity's maximum lifetime, strictly positive
     */
    public Lifetime(float seconds) {
        if (seconds <= 0f) {
            throw new IllegalArgumentException(
                "a lifetime needs a strictly positive duration, was " + seconds);
        }
        this.remaining = seconds;
    }
}
