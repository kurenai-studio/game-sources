package dev.luchoc.littlespaceship.game.adapter.content;

import com.badlogic.gdx.utils.JsonValue;
import dev.luchoc.littlespaceship.core.port.BalanceValues;

/**
 * The straightforward {@link BalanceValues}, built once from {@code assets/data/balance.json}.
 *
 * <p>Every field is required in the file — there is no default here, on the same reasoning
 * {@link dev.luchoc.littlespaceship.core.port.ComponentSpec} settled on in {@code core}: a missing
 * balance number silently falling back to a guess is a worse failure than the game refusing to
 * start until content names it.
 *
 * @param initialLives lives the player starts a run with
 * @param maxLives lives the player can never exceed
 * @param initialBombs bombs the player starts a run with
 * @param maxBombs bombs the player can never exceed
 * @param weaponLevels number of shot levels, the base one included
 * @param respawnInvulnerability seconds of invulnerability after respawning
 * @param damageInvulnerability seconds of invulnerability after a hit absorbed by shield or
 *     attachment
 * @param maxedPickupBonus points awarded when a power-up is picked up at maximum
 * @param playerSpeed the ship's top speed, in logical units per second
 * @param playerSlowFactor multiplier applied to {@code playerSpeed} while the precision control is
 *     held
 * @param playerStartX horizontal position the ship is created at
 * @param playerStartY vertical position the ship is created at
 * @param weaponFireCooldown seconds between two volleys of the main weapon
 * @param weaponProjectileSpeed speed of a player projectile once fired
 * @param pickupRadius radius of a pickup's collider
 * @param invulnerabilityPickupDuration seconds of invulnerability granted by the invulnerability
 *     power-up
 * @param lifeCompletionBonus points awarded per remaining life when the level is completed
 * @param bombCompletionBonus points awarded per remaining bomb when the level is completed
 * @param weaponProjectileDamage hit points a player projectile subtracts from an enemy's health
 * @param bombDamage hit points the bomb subtracts from a resistant enemy's health
 * @param pickupFallSpeed magnitude of the downward speed a dropped pickup falls at, overriding
 *     {@link BalanceValues}'s own {@code default} so a change to {@code balance.json}'s value is
 *     not silently inert
 */
public record JsonBalanceValues(
    int initialLives,
    int maxLives,
    int initialBombs,
    int maxBombs,
    int weaponLevels,
    float respawnInvulnerability,
    float damageInvulnerability,
    int maxedPickupBonus,
    float playerSpeed,
    float playerSlowFactor,
    float playerStartX,
    float playerStartY,
    float weaponFireCooldown,
    float weaponProjectileSpeed,
    float pickupRadius,
    float invulnerabilityPickupDuration,
    int lifeCompletionBonus,
    int bombCompletionBonus,
    int weaponProjectileDamage,
    int bombDamage,
    float pickupFallSpeed) implements BalanceValues {

    /**
     * Reads every field from the parsed {@code balance.json} root. Every {@code get*(String)}
     * overload used here (with no default argument) throws if the key is missing or the value is
     * the wrong type, which is what lets the loader's caller wrap the failure with the file name.
     *
     * @param root the parsed root object of {@code balance.json}
     * @return the balance values it describes
     */
    static JsonBalanceValues from(JsonValue root) {
        return new JsonBalanceValues(
            root.getInt("initialLives"),
            root.getInt("maxLives"),
            root.getInt("initialBombs"),
            root.getInt("maxBombs"),
            root.getInt("weaponLevels"),
            root.getFloat("respawnInvulnerability"),
            root.getFloat("damageInvulnerability"),
            root.getInt("maxedPickupBonus"),
            root.getFloat("playerSpeed"),
            root.getFloat("playerSlowFactor"),
            root.getFloat("playerStartX"),
            root.getFloat("playerStartY"),
            root.getFloat("weaponFireCooldown"),
            root.getFloat("weaponProjectileSpeed"),
            root.getFloat("pickupRadius"),
            root.getFloat("invulnerabilityPickupDuration"),
            root.getInt("lifeCompletionBonus"),
            root.getInt("bombCompletionBonus"),
            root.getInt("weaponProjectileDamage"),
            root.getInt("bombDamage"),
            root.getFloat("pickupFallSpeed"));
    }
}
