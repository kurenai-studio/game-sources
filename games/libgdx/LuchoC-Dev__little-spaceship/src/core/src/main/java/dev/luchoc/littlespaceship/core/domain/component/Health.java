package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Hit points, for the enemies and the boss that need more than one hit to go down.
 *
 * <p>Named in {@code 12-architecture.md}'s component table from the start — {@code "health": {
 * "points": 40 }} is that document's own example for a tank — but never built until now: phase 04
 * modelled "does this enemy die outright" as {@link Collider#fragile} instead, and phase 05's plan
 * did not list the architecture document among its required reading, so the gap went unnoticed
 * through both phases. It is not a second mechanism competing with {@code fragile}: {@code
 * DamageSystem} and {@code BombSystem} both treat an enemy with no {@code Health} component as
 * having exactly one point, so "no component" is shorthand for the weakest case of this one, not an
 * alternative rule that could disagree with it. {@link Collider#fragile} answers a different
 * question entirely — whether a ramming or a bomb kills the enemy's whole body outright, independent
 * of how much sustained weapon damage it can take.
 *
 * <p>No enemy hit-point value is decided in {@code 10-mvp-initial-values.md}; the architecture
 * document's {@code 40} is illustrative, not adopted. See {@code
 * BalanceValues#weaponProjectileDamage()} and {@code BalanceValues#bombDamage()} for the two
 * provisional numbers this component is measured against.
 */
public final class Health {

    /** Hit points remaining. The component's holder is destroyed once this reaches zero or below. */
    public int points;

    /**
     * @param points starting hit points, strictly positive
     */
    public Health(int points) {
        if (points <= 0) {
            throw new IllegalArgumentException("health needs strictly positive points, was " + points);
        }
        this.points = points;
    }
}
