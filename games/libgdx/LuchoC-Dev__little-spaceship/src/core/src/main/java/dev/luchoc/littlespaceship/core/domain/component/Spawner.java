package dev.luchoc.littlespaceship.core.domain.component;

/**
 * What an entity periodically spawns near itself — the heavy carrier's own rule, per
 * {@code 02-mvp-functional-spec.md}: "very slow, high health, does not shoot and spawns basic
 * enemies periodically". Named in {@code 12-architecture.md}'s component table ("what it spawns and
 * how often, for the carrier") since the MVP's very first draft, built only once the strong
 * encounter of phase 07 gave it a real consumer: two carriers, whose entire reason for being the
 * strong encounter is the sustained pressure this component produces.
 *
 * <p>Data-driven like every archetype component: which archetype spawns, how often, and where
 * relative to the holder — so {@code level-designer} can tune the encounter (a faster interval, a
 * different archetype, a repositioned spawn point) without touching {@code core} at all.
 */
public final class Spawner {

    /** Content id of the {@code EnemyDefinition} spawned. */
    public String enemyId;

    /** Seconds between two spawns. */
    public float interval;

    /** Horizontal offset from the holder's own position, positive to the right. */
    public float offsetX;

    /** Vertical offset from the holder's own position, positive upwards like {@code Transform}. */
    public float offsetY;

    /**
     * Seconds left before the next spawn. Starts at {@code interval}, not zero: a carrier's first
     * child appears one full interval after the carrier itself does, not the instant it spawns.
     */
    public float timer;

    /**
     * @param enemyId content id of the archetype spawned, never null or empty
     * @param interval seconds between two spawns, strictly positive
     * @param offsetX horizontal offset from the holder, in logical units
     * @param offsetY vertical offset from the holder, in logical units
     */
    public Spawner(String enemyId, float interval, float offsetX, float offsetY) {
        if (enemyId == null || enemyId.isEmpty()) {
            throw new IllegalArgumentException("a spawner needs an enemy id");
        }
        if (interval <= 0f) {
            throw new IllegalArgumentException("a spawner needs a strictly positive interval, was " + interval);
        }
        this.enemyId = enemyId;
        this.interval = interval;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.timer = interval;
    }
}
