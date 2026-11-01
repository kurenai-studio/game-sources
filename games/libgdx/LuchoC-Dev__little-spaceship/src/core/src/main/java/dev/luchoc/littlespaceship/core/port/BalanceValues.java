package dev.luchoc.littlespaceship.core.port;

/**
 * The numbers that decide how the game feels.
 *
 * <p>They live outside the code because their purpose is to change during balancing: the adapter
 * reads them from content and the simulation asks for them. The starting values are recorded in
 * {@code docs/planning/10-mvp-initial-values.md}, and none of them is definitive.
 *
 * <p>Only the values the simulation already consumes are declared. The rest arrive with the systems
 * that read them.
 */
public interface BalanceValues {

    /**
     * @return lives the player starts a run with
     */
    int initialLives();

    /**
     * @return lives the player can never exceed, so stacking them does not remove all tension
     */
    int maxLives();

    /**
     * @return bombs the player starts a run with
     */
    int initialBombs();

    /**
     * @return bombs the player can never exceed
     */
    int maxBombs();

    /**
     * @return number of shot levels, the base one included
     */
    int weaponLevels();

    /**
     * @return seconds of invulnerability after respawning
     */
    float respawnInvulnerability();

    /**
     * @return seconds of invulnerability after a hit absorbed by shield or attachment
     */
    float damageInvulnerability();

    /**
     * @return points awarded when a power-up is picked up at maximum, so the drop is never wasted
     */
    int maxedPickupBonus();

    /**
     * Top speed of the player's ship, in logical units per second. The movement vector is clamped to
     * this magnitude regardless of direction, which is what keeps diagonal movement no faster than
     * a single axis.
     *
     * <p>Not yet in {@code 10-mvp-initial-values.md}: the document fixes the movement policy —
     * additive devices, clamped result — but not a concrete speed. This is a placeholder pending
     * that number being added during balancing.
     *
     * @return the ship's top speed
     */
    float playerSpeed();

    /**
     * Multiplier applied to {@link #playerSpeed()} while the precision control is held.
     *
     * <p>Slow movement is a multiplier and not a separate mode: the same clamp is used with a
     * smaller cap. Also missing from {@code 10-mvp-initial-values.md}, for the same reason as
     * {@link #playerSpeed()}.
     *
     * @return a value in {@code (0, 1]}
     */
    float playerSlowFactor();

    /**
     * Horizontal position the player's ship is created at when a run starts.
     *
     * <p>Not yet in {@code 10-mvp-initial-values.md}: nothing in the planning docs fixes a number
     * for where the ship begins, only that it is inside the 208-unit-wide playfield. A placeholder
     * pending a real number from balancing, same status as {@link #playerSpeed()}.
     *
     * @return the starting x position, in logical units
     */
    float playerStartX();

    /**
     * Vertical position the player's ship is created at when a run starts.
     *
     * <p>Same status as {@link #playerStartX()}: a placeholder, not yet in
     * {@code 10-mvp-initial-values.md}.
     *
     * @return the starting y position, in logical units, growing upwards like {@code Transform}
     */
    float playerStartY();

    /**
     * Seconds between two volleys of the main weapon while the fire control is held.
     *
     * <p>Not yet in {@code 10-mvp-initial-values.md}: the document fixes the shot level count and
     * how a level is told apart visually, but not a rate of fire. A placeholder pending balancing,
     * same status as {@link #playerSpeed()}.
     *
     * @return the cooldown between volleys, strictly positive
     */
    float weaponFireCooldown();

    /**
     * Speed of a player projectile once fired, in logical units per second, positive since {@code
     * Transform.y} and the player's own position both grow upwards towards where enemies are.
     *
     * <p>Same placeholder status as {@link #weaponFireCooldown()}.
     *
     * @return the player projectile's speed
     */
    float weaponProjectileSpeed();

    /**
     * Radius of a pickup's collider, in logical units.
     *
     * <p>{@code docs/design/02-sprite-sizes.md} states the policy — a pickup's hitbox is larger
     * than its sprite, "they feel magnetic" — but names no concrete radius for any pickup, unlike
     * the ships, projectiles and enemies the same document does size. A placeholder pending that
     * number and pending pickup art existing at all.
     *
     * @return the pickup collider's radius
     */
    float pickupRadius();

    /**
     * Speed at which a dropped pickup falls once it exists, in logical units per second, growing
     * downward the same way a descending enemy's vertical velocity does — the caller negates it
     * before writing it into {@code Motion.vy} since {@code Transform.y} grows upward.
     *
     * <p>Without this a pickup has no {@code Motion} at all and hangs exactly where its carrier
     * died, which reads as pinned to the window rather than part of a scrolling world (issue #252).
     * A feel question, not an arithmetic one: reported by {@link
     * dev.luchoc.littlespaceship.core.domain.system.CleanupSystem} to fall at the background's own
     * rate, faster reads as dropping, slower as floating — settled by the project owner playing it,
     * same as {@link #playerSpeed()}.
     *
     * <p><b>Default, not abstract:</b> {@code JsonBalanceValues} (in {@code game}, not {@code core})
     * is a record enumerating every {@code balance.json} key by hand, so an abstract addition here
     * would fail the whole-repo build before {@code game} adds the field — the same reasoning {@code
     * ContentSource.wave(String)} used in phase 11b. The value returned here is a placeholder that
     * must be kept equal to {@code assets/data/balance.json}'s own {@code pickupFallSpeed} by hand
     * until {@code game-presentation} wires the key into {@code JsonBalanceValues}, at which point
     * this should become abstract like every other value on this interface.
     *
     * @return the fall speed's magnitude, strictly positive
     */
    default float pickupFallSpeed() {
        return 20f;
    }

    /**
     * Seconds of invulnerability granted by the invulnerability power-up.
     *
     * <p>Not yet in {@code 10-mvp-initial-values.md}: the document lists invulnerability among the
     * MVP power-ups but gives no duration for it, only for the two damage-triggered grants ({@link
     * #respawnInvulnerability()} and {@link #damageInvulnerability()}). A placeholder pending
     * balancing.
     *
     * @return the duration granted by the pickup, strictly positive
     */
    float invulnerabilityPickupDuration();

    /**
     * Points awarded per remaining life when the level is completed.
     *
     * @return the per-life completion bonus, from the score table in
     *     {@code 10-mvp-initial-values.md}
     */
    int lifeCompletionBonus();

    /**
     * Points awarded per remaining bomb when the level is completed.
     *
     * @return the per-bomb completion bonus, from the score table in
     *     {@code 10-mvp-initial-values.md}
     */
    int bombCompletionBonus();

    /**
     * Hit points a player projectile subtracts from an enemy's {@code Health} on contact.
     *
     * <p>Not in {@code 10-mvp-initial-values.md}: no enemy hit-point value is decided anywhere in
     * {@code docs/planning/} yet, so there is nothing to balance this number against. A placeholder
     * pending real numbers, recorded as open the same way {@link #playerSpeed()} is. {@code
     * 01-vision-and-scope.md} is explicit that difficulty "must not depend only on raising health
     * and damage" — this value is a fixed per-shot constant for that reason, not a per-level or
     * per-difficulty dial.
     *
     * @return the damage a single player projectile deals, strictly positive
     */
    int weaponProjectileDamage();

    /**
     * Hit points the bomb subtracts from a non-fragile enemy's {@code Health} on detonation — the
     * "heavy damage to resistant enemies" {@code 02-mvp-functional-spec.md} describes. A fragile
     * enemy ignores this entirely: it is destroyed outright by the bomb, the same as by ramming,
     * regardless of any {@code Health} it happens to carry.
     *
     * <p>Same placeholder status as {@link #weaponProjectileDamage()}.
     *
     * @return the damage the bomb deals to a resistant enemy, strictly positive
     */
    int bombDamage();
}
