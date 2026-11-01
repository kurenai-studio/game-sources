package dev.luchoc.littlespaceship.core.domain.component;

import dev.luchoc.littlespaceship.core.port.InvulnerabilitySource;

/**
 * Remaining grace time during which the holder ignores damage entirely.
 *
 * <p>Granted and decayed only by {@code DamageSystem}, the single place the defensive chain lives
 * — with one exception: {@code PickupSystem} also grants it directly, for the invulnerability
 * power-up, which is not a consequence of a hit at all. Three durations feed it in total, all read
 * from {@code BalanceValues}: a longer one after a life is lost, a shorter one after a hit absorbed
 * by the shield or the attachment — both a confirmed, late addition to the spec recorded in
 * {@code 08-decisions-and-open-items.md} — and the power-up's own duration.
 *
 * <p>{@link #source} records which of the three granted the current grace period, purely for
 * presentation: {@code 04-hud-layout.md} asks the three to look different on the ship, and nothing
 * inside the core reads this field back to decide behaviour — the chain treats every active grace
 * period identically regardless of why it started.
 */
public final class Invulnerable {

    /** Seconds of grace left. The component is removed once this reaches zero. */
    public float remaining;

    /** Which of the three grants is currently active. */
    public InvulnerabilitySource source;

    /**
     * Creates the grace period.
     *
     * @param remaining seconds of grace, strictly positive
     * @param source which grant this is, never {@link InvulnerabilitySource#NONE}
     */
    public Invulnerable(float remaining, InvulnerabilitySource source) {
        this.remaining = remaining;
        this.source = source;
    }
}
