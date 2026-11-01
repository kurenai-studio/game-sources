package dev.luchoc.littlespaceship.core.testsupport;

import dev.luchoc.littlespaceship.core.port.BalanceValues;

/**
 * A configurable {@link BalanceValues} for tests, defaulted to the values in
 * {@code 10-mvp-initial-values.md} wherever the document fixes one. {@code playerSpeed} and
 * {@code playerSlowFactor} are not in that document yet; the defaults here are placeholders, same as
 * the ones documented on {@link BalanceValues}.
 *
 * <p>Public fields, on purpose: this is test fixture code, not domain data, so a test overrides
 * exactly the value its scenario needs and reads the rest from the default.
 */
public final class TestBalance implements BalanceValues {

    public int initialLives = 3;
    public int maxLives = 5;
    public int initialBombs = 2;
    public int maxBombs = 3;
    public int weaponLevels = 4;
    public float respawnInvulnerability = 2f;
    public float damageInvulnerability = 1f;
    public int maxedPickupBonus = 500;
    public float playerSpeed = 140f;
    public float playerSlowFactor = 0.45f;
    public float playerStartX = 104f;
    public float playerStartY = 30f;
    public float weaponFireCooldown = 0.15f;
    public float weaponProjectileSpeed = 220f;
    public float pickupRadius = 6f;
    public float pickupFallSpeed = 20f;
    public float invulnerabilityPickupDuration = 3f;
    public int lifeCompletionBonus = 1000;
    public int bombCompletionBonus = 300;
    public int weaponProjectileDamage = 10;
    public int bombDamage = 50;

    @Override
    public int initialLives() {
        return initialLives;
    }

    @Override
    public int maxLives() {
        return maxLives;
    }

    @Override
    public int initialBombs() {
        return initialBombs;
    }

    @Override
    public int maxBombs() {
        return maxBombs;
    }

    @Override
    public int weaponLevels() {
        return weaponLevels;
    }

    @Override
    public float respawnInvulnerability() {
        return respawnInvulnerability;
    }

    @Override
    public float damageInvulnerability() {
        return damageInvulnerability;
    }

    @Override
    public int maxedPickupBonus() {
        return maxedPickupBonus;
    }

    @Override
    public float playerSpeed() {
        return playerSpeed;
    }

    @Override
    public float playerSlowFactor() {
        return playerSlowFactor;
    }

    @Override
    public float playerStartX() {
        return playerStartX;
    }

    @Override
    public float playerStartY() {
        return playerStartY;
    }

    @Override
    public float weaponFireCooldown() {
        return weaponFireCooldown;
    }

    @Override
    public float weaponProjectileSpeed() {
        return weaponProjectileSpeed;
    }

    @Override
    public float pickupRadius() {
        return pickupRadius;
    }

    @Override
    public float pickupFallSpeed() {
        return pickupFallSpeed;
    }

    @Override
    public float invulnerabilityPickupDuration() {
        return invulnerabilityPickupDuration;
    }

    @Override
    public int lifeCompletionBonus() {
        return lifeCompletionBonus;
    }

    @Override
    public int bombCompletionBonus() {
        return bombCompletionBonus;
    }

    @Override
    public int weaponProjectileDamage() {
        return weaponProjectileDamage;
    }

    @Override
    public int bombDamage() {
        return bombDamage;
    }
}
