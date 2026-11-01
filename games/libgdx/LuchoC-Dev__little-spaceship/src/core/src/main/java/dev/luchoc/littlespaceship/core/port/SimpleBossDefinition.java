package dev.luchoc.littlespaceship.core.port;

/**
 * The straightforward {@link BossDefinition}.
 *
 * @param id the content id
 * @param entersAt seconds since the level started when the entrance begins
 * @param coreHealth hit points of the core part
 * @param podHealth hit points of each pod part
 * @param armHealth hit points of each arm part
 * @param corePoints score points awarded for destroying the core
 * @param podPoints score points awarded for destroying a pod
 * @param armPoints score points awarded for destroying an arm
 * @param entranceSpeed vertical descent speed during the entrance
 * @param combatY the {@code Transform.y} the core holds during the fight
 * @param patternCooldown seconds between the end of one attack and the tell of the next
 * @param spreadProjectileSpeed speed of a spread-pattern projectile
 * @param sweepProjectileSpeed speed of a sweep-pattern projectile
 */
public record SimpleBossDefinition(
    String id,
    float entersAt,
    int coreHealth,
    int podHealth,
    int armHealth,
    int corePoints,
    int podPoints,
    int armPoints,
    float entranceSpeed,
    float combatY,
    float patternCooldown,
    float spreadProjectileSpeed,
    float sweepProjectileSpeed) implements BossDefinition {

    /**
     * Rejects a boss that names nothing, that could never be reached or defeated, or whose fight
     * would never move or attack.
     */
    public SimpleBossDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("a boss definition needs an id");
        }
        if (entersAt < 0f || Float.isNaN(entersAt) || Float.isInfinite(entersAt)) {
            throw new IllegalArgumentException("boss '" + id + "' needs a finite, non-negative entersAt");
        }
        if (coreHealth <= 0 || podHealth <= 0 || armHealth <= 0) {
            throw new IllegalArgumentException(
                "boss '" + id + "' needs strictly positive health for every part");
        }
        if (entranceSpeed <= 0f) {
            throw new IllegalArgumentException("boss '" + id + "' needs a strictly positive entranceSpeed");
        }
        if (patternCooldown <= 0f) {
            throw new IllegalArgumentException("boss '" + id + "' needs a strictly positive patternCooldown");
        }
        if (spreadProjectileSpeed <= 0f || sweepProjectileSpeed <= 0f) {
            throw new IllegalArgumentException(
                "boss '" + id + "' needs strictly positive projectile speeds");
        }
    }
}
