package dev.luchoc.littlespaceship.game.adapter.content;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Proves {@link JsonBalanceValues#from(JsonValue)} actually reads its fields from the parsed JSON,
 * rather than an accessor happening to agree with {@link
 * dev.luchoc.littlespaceship.core.port.BalanceValues}'s own {@code default}.
 *
 * <p>This is the check {@code reviewer} asked for on PR #262 (issue #261): every prior assertion in
 * this codebase read a {@code BalanceValues} accessor, never a value parsed from a fixture, so
 * nothing distinguished "the value came from JSON" from "the value came from a hardcoded default
 * that happens to match". {@link #pickupFallSpeedComesFromTheFileNotTheDefault()} uses a fixture
 * value ({@code 33.0}) chosen precisely because {@link
 * dev.luchoc.littlespaceship.core.port.BalanceValues#pickupFallSpeed()}'s default of {@code 20f}
 * cannot satisfy the assertion — removing the {@code root.getFloat("pickupFallSpeed")} read from
 * {@link JsonBalanceValues#from(JsonValue)} turns this test red. Verified by temporarily removing
 * that read and the {@code pickupFallSpeed} constructor argument (falling back to a literal
 * {@code 20f}): the test failed with "expected: <33.0> but was: <20.0>", then the change was
 * reverted and the test passed again.
 */
final class JsonBalanceValuesTest {

    /**
     * A minimal but complete {@code balance.json} fixture: every key {@link JsonBalanceValues#from}
     * reads, so parsing does not fail on a missing one, with {@code pickupFallSpeed} set to a value
     * ({@code 33.0}) far enough from the interface's {@code 20f} default that the two cannot be
     * confused.
     */
    private static final String FIXTURE = """
        {
          "initialLives": 3,
          "maxLives": 5,
          "initialBombs": 2,
          "maxBombs": 3,
          "weaponLevels": 4,
          "respawnInvulnerability": 2.0,
          "damageInvulnerability": 1.0,
          "maxedPickupBonus": 500,
          "playerSpeed": 140,
          "playerSlowFactor": 0.45,
          "playerStartX": 104,
          "playerStartY": 30,
          "weaponFireCooldown": 0.15,
          "weaponProjectileSpeed": 220,
          "pickupRadius": 6.0,
          "pickupFallSpeed": 33.0,
          "invulnerabilityPickupDuration": 3.0,
          "lifeCompletionBonus": 1000,
          "bombCompletionBonus": 300,
          "weaponProjectileDamage": 10,
          "bombDamage": 50
        }
        """;

    @Test
    @DisplayName("pickupFallSpeed comes from the parsed file, not BalanceValues's default")
    void pickupFallSpeedComesFromTheFileNotTheDefault() {
        JsonValue root = new JsonReader().parse(FIXTURE);

        JsonBalanceValues balance = JsonBalanceValues.from(root);

        assertEquals(33.0f, balance.pickupFallSpeed());
    }
}
