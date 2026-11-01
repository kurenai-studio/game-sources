package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionHit;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionPair;
import dev.luchoc.littlespaceship.core.domain.component.Attachment;
import dev.luchoc.littlespaceship.core.domain.component.Invulnerable;
import dev.luchoc.littlespaceship.core.domain.component.Pickup;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Shield;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.InvulnerabilitySource;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Every power-up kind, covered by its own consumption rule, plus the shared "maxed pickup grants
 * points instead of being wasted" rule per {@code 10-mvp-initial-values.md}.
 */
class PickupSystemTest {

    private static final float STEP = 1f / 60f;

    private final TestBalance balance = new TestBalance();
    private final TestContent content = new TestContent(balance);
    private final World world = new World(content, new Rng(1), new GameEventQueue());
    private final PickupSystem system = new PickupSystem();

    @Test
    @DisplayName("the weapon upgrade raises the shot level by one")
    void weaponUpgradeRaisesShotLevel() {
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_WEAPON_UPGRADE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(2, world.players().get(player).shotLevel);
        assertTrue(world.pendingDestruction().contains(pickup));
    }

    @Test
    @DisplayName("the weapon upgrade at maximum grants points instead of raising the level further")
    void weaponUpgradeAtMaximumGrantsPoints() {
        int player = spawnPlayer(new Player(3, 2, balance.weaponLevels));
        int pickup = spawnPickup(PickupSystem.KIND_WEAPON_UPGRADE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.weaponLevels, world.players().get(player).shotLevel);
        assertEquals(balance.maxedPickupBonus, world.scoreValues().get(pickup).points);
    }

    @Test
    @DisplayName("the shield pickup grants a shield when the player has none")
    void shieldGrantsAShield() {
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_SHIELD);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertTrue(world.shields().has(player));
    }

    @Test
    @DisplayName("the shield pickup while already shielded grants points instead")
    void shieldAlreadyPresentGrantsPoints() {
        int player = spawnPlayer(new Player(3, 2, 1));
        world.shields().set(player, new Shield());
        int pickup = spawnPickup(PickupSystem.KIND_SHIELD);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.maxedPickupBonus, world.scoreValues().get(pickup).points);
    }

    @Test
    @DisplayName("the extra life pickup raises lives by one, capped at the maximum")
    void extraLifeRaisesLivesUpToTheCap() {
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_EXTRA_LIFE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(4, world.players().get(player).lives);
    }

    @Test
    @DisplayName("the extra life pickup at maximum grants points instead")
    void extraLifeAtMaximumGrantsPoints() {
        int player = spawnPlayer(new Player(balance.maxLives, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_EXTRA_LIFE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.maxLives, world.players().get(player).lives);
        assertEquals(balance.maxedPickupBonus, world.scoreValues().get(pickup).points);
    }

    @Test
    @DisplayName("the bomb recharge pickup raises bombs by one, capped at the maximum")
    void bombRechargeRaisesBombsUpToTheCap() {
        int player = spawnPlayer(new Player(3, 1, 1));
        int pickup = spawnPickup(PickupSystem.KIND_BOMB_RECHARGE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(2, world.players().get(player).bombs);
    }

    @Test
    @DisplayName("the bomb recharge pickup at maximum grants points instead")
    void bombRechargeAtMaximumGrantsPoints() {
        int player = spawnPlayer(new Player(3, balance.maxBombs, 1));
        int pickup = spawnPickup(PickupSystem.KIND_BOMB_RECHARGE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.maxBombs, world.players().get(player).bombs);
        assertEquals(balance.maxedPickupBonus, world.scoreValues().get(pickup).points);
    }

    @Test
    @DisplayName("the invulnerability pickup grants the configured duration")
    void invulnerabilityGrantsTheConfiguredDuration() {
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_INVULNERABILITY);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.invulnerabilityPickupDuration,
            world.invulnerabilities().get(player).remaining, 0.0001f);
        assertEquals(InvulnerabilitySource.POWERUP, world.invulnerabilities().get(player).source);
    }

    @Test
    @DisplayName("the invulnerability pickup while already at or above that duration grants points")
    void invulnerabilityAlreadyAtCapGrantsPoints() {
        int player = spawnPlayer(new Player(3, 2, 1));
        world.invulnerabilities().set(player,
            new Invulnerable(balance.invulnerabilityPickupDuration, InvulnerabilitySource.POWERUP));
        int pickup = spawnPickup(PickupSystem.KIND_INVULNERABILITY);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.maxedPickupBonus, world.scoreValues().get(pickup).points);
    }

    @Test
    @DisplayName("the attachment pickup equips an attachment with durability read from content")
    void attachmentPickupEquipsFromContent() {
        content.withAttachment(3);
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_ATTACHMENT);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        Attachment attachment = world.attachments().get(player);
        assertEquals(3, attachment.durability);
        assertEquals("attachment", attachment.id);
    }

    @Test
    @DisplayName("a tougher attachment definition changes durability with no code change")
    void attachmentDurabilityComesFromDataNotAConstant() {
        content.withAttachment(7);
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_ATTACHMENT);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(7, world.attachments().get(player).durability);
    }

    @Test
    @DisplayName("the attachment pickup while already equipped grants points instead")
    void attachmentAlreadyEquippedGrantsPoints() {
        content.withAttachment(3);
        int player = spawnPlayer(new Player(3, 2, 1));
        world.attachments().set(player, new Attachment("attachment", 1));
        int pickup = spawnPickup(PickupSystem.KIND_ATTACHMENT);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(1, world.attachments().get(player).durability, "the existing attachment is untouched");
        assertEquals(balance.maxedPickupBonus, world.scoreValues().get(pickup).points);
    }

    @Test
    @DisplayName("a pickup with no ScoreValue attached was not maxed, and the entity is still consumed")
    void nonMaxedPickupCarriesNoScoreValue() {
        int player = spawnPlayer(new Player(3, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_SHIELD);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);

        assertNull(world.scoreValues().get(pickup));
        assertTrue(world.pendingDestruction().contains(pickup));
    }

    @Test
    @DisplayName("a maxed pickup increases the player's score once ScoreSystem sweeps it")
    void maxedPickupIncreasesTheScoreOnceSwept() {
        int player = spawnPlayer(new Player(balance.maxLives, 2, 1));
        int pickup = spawnPickup(PickupSystem.KIND_EXTRA_LIFE);
        hit(pickup, player);

        system.update(world, STEP, InputFrame.IDLE);
        new ScoreSystem().update(world, STEP, InputFrame.IDLE);

        assertEquals(balance.maxedPickupBonus, world.players().get(player).score);
    }

    @Test
    @DisplayName("does nothing when there is no player entity")
    void noPlayerIsHarmless() {
        int pickup = spawnPickup(PickupSystem.KIND_SHIELD);
        world.collisionHits().add(new CollisionHit(pickup, 999, CollisionPair.PICKUP_VS_PLAYER));

        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.pendingDestruction().contains(pickup));
    }

    private void hit(int pickup, int player) {
        world.collisionHits().add(new CollisionHit(pickup, player, CollisionPair.PICKUP_VS_PLAYER));
    }

    private int spawnPickup(String kind) {
        int pickup = world.createEntity();
        world.pickups().set(pickup, new Pickup(kind));
        return pickup;
    }

    private int spawnPlayer(Player player) {
        int entity = world.createEntity();
        world.players().set(entity, player);
        return entity;
    }
}
