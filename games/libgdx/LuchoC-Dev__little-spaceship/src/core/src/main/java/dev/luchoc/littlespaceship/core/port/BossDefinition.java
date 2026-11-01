package dev.luchoc.littlespaceship.core.port;

/**
 * The numbers that decide how a level's boss fights, looked up by level id the same way a {@link
 * WaveTimeline} is.
 *
 * <p>What the boss is made of — five parts, their offsets and their radii — is not here: {@code
 * docs/design/02-sprite-sizes.md} fixes that footprint as an art fact, the same way {@code
 * Simulation} hardcodes the player's collider radius instead of reading it from {@link
 * BalanceValues}. This interface carries only what genuinely varies with balancing: how tough each
 * part is, when the fight starts, how it moves into position and how fast its attacks travel.
 *
 * <p>{@code 08-decisions-and-open-items.md} settles the shape the numbers here serve: one phase, two
 * alternating attack patterns — spread from the pods, sweep from the arms — each preceded by a
 * three-beat, 0.75 s tell. The tell's own timing is an art fact fixed in {@code
 * docs/design/06-boss-presentation.md}, not a balance value, so it is not declared here either.
 */
public interface BossDefinition {

    /**
     * @return the content id
     */
    String id();

    /**
     * @return seconds since the level started when the boss's entrance begins
     */
    float entersAt();

    /**
     * @return hit points of the core part; the fight ends the instant this reaches zero
     */
    int coreHealth();

    /**
     * @return hit points of each pod part
     */
    int podHealth();

    /**
     * @return hit points of each arm part
     */
    int armHealth();

    /**
     * @return score points awarded for destroying the core
     */
    int corePoints();

    /**
     * @return score points awarded for destroying a pod
     */
    int podPoints();

    /**
     * @return score points awarded for destroying an arm
     */
    int armPoints();

    /**
     * @return vertical speed the boss descends at during its entrance, in logical units per second
     */
    float entranceSpeed();

    /**
     * @return the {@code Transform.y} the core holds once the entrance ends and the fight begins
     */
    float combatY();

    /**
     * @return seconds between the end of one attack and the tell of the next
     */
    float patternCooldown();

    /**
     * @return speed of a spread-pattern projectile, in logical units per second
     */
    float spreadProjectileSpeed();

    /**
     * @return speed of a sweep-pattern projectile, in logical units per second
     */
    float sweepProjectileSpeed();
}
