package dev.luchoc.littlespaceship.core.domain.component;

/**
 * An enemy archetype's own firing pattern: how often it fires, what shape and how fast the shot
 * leaves. Data-driven per archetype, the same treatment {@link Spawner} already gets — {@code
 * enemy-shooter} is content, not a class, exactly like every other archetype component {@code
 * ComponentFactoryRegistry} attaches.
 *
 * <p>Distinct from the player's {@link Weapon}: that one carries only a timer, because rate and
 * pattern are either global ({@code BalanceValues.weaponFireCooldown()}) or read from {@code
 * Player.shotLevel} by {@code WeaponSystem} itself. An enemy has neither a global rate nor a shot
 * level — its rate and pattern genuinely vary per archetype — so both travel on the component
 * instead, the same shape {@code 12-architecture.md}'s own {@code "weapon": { "rate": 2.2, "pattern":
 * "straight-single" }} example already implies.
 *
 * <p>{@code pattern} names a shot shape {@code EnemyWeaponSystem} knows how to build — {@code
 * "straight-single"} is the only one the MVP needs, per {@code 02-mvp-functional-spec.md}'s
 * "evolved basic or shooter: similar to the basic one with a higher rate of fire". A second shape
 * would be a second case in that system, not a new content contract: nothing here justifies a
 * general {@code PatternDefinition} the way {@code content-pipeline-design} already rejected one for
 * lack of a second real case.
 *
 * <p>{@code firstShotDelay} is content's optional fourth field, read through {@code
 * ComponentSpec#numberOr}, falling back to {@code cooldown} when absent so existing content keeps
 * firing exactly when it already did. It exists because a shot's readable delay and the rate two
 * shots repeat at are two different design decisions that only coincided by accident while a single
 * archetype ({@code enemy-shooter}) was the only one that fired: {@code cooldown} was reused for both,
 * so a "slow shot" archetype with a long {@code cooldown} silently also got a long, unplayed-out wait
 * before ever firing once. Named for what it delays, not for how it relates to {@code cooldown} — this
 * component already has one field, {@code cooldown} itself, whose content name ({@code "rate"}) means
 * the opposite of what it sounds like; a second confusing name here would compound that instead of
 * fixing it.
 */
public final class EnemyWeapon {

    /** A shot shape {@code EnemyWeaponSystem} knows how to build, such as {@code "straight-single"}. */
    public final String pattern;

    /** Seconds between two shots. Confusingly named {@code "rate"} in content, per the architecture
     * document's own example — a lower number fires more often, exactly like {@code Weapon}'s own
     * cooldown. */
    public final float cooldown;

    /** Speed of the fired projectile, in logical units per second, always positive: the pattern
     * itself decides direction. */
    public final float projectileSpeed;

    /** Seconds left before the next shot. Starts at {@code firstShotDelay}, not zero — so an enemy
     * does not fire the instant it spawns, the same reasoning {@link Spawner#timer} already applies
     * to spawning itself. After the first shot this counts down from {@code cooldown} instead, like
     * every {@code Spawner} respawn already does. */
    public float cooldownRemaining;

    /**
     * @param pattern the shot shape, never null or empty
     * @param cooldown seconds between two shots after the first, strictly positive
     * @param projectileSpeed the fired projectile's speed, strictly positive
     */
    public EnemyWeapon(String pattern, float cooldown, float projectileSpeed) {
        this(pattern, cooldown, projectileSpeed, cooldown);
    }

    /**
     * @param pattern the shot shape, never null or empty
     * @param cooldown seconds between two shots after the first, strictly positive
     * @param projectileSpeed the fired projectile's speed, strictly positive
     * @param firstShotDelay seconds from spawn to the first shot, strictly positive — content wants
     *     this shorter than {@code cooldown} for archetypes whose cooldown is itself long (a "slow
     *     shot" enemy should not also make the player wait a slow cooldown for the first bullet to
     *     prove it shoots at all). Zero is rejected rather than treated as "fire on the first tick":
     *     a projectile appearing the same frame as its owner is unreadable, exactly the case the
     *     {@code cooldownRemaining} javadoc above already argues against, and a zero here would let
     *     content silently reintroduce it.
     */
    public EnemyWeapon(String pattern, float cooldown, float projectileSpeed, float firstShotDelay) {
        if (pattern == null || pattern.isEmpty()) {
            throw new IllegalArgumentException("an enemy weapon needs a pattern");
        }
        if (cooldown <= 0f) {
            throw new IllegalArgumentException("an enemy weapon needs a strictly positive cooldown, was " + cooldown);
        }
        if (projectileSpeed <= 0f) {
            throw new IllegalArgumentException(
                "an enemy weapon needs a strictly positive projectile speed, was " + projectileSpeed);
        }
        if (firstShotDelay <= 0f) {
            throw new IllegalArgumentException(
                "an enemy weapon needs a strictly positive first shot delay, was " + firstShotDelay);
        }
        this.pattern = pattern;
        this.cooldown = cooldown;
        this.projectileSpeed = projectileSpeed;
        this.cooldownRemaining = firstShotDelay;
    }
}
