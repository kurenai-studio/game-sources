package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionHit;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionPair;
import dev.luchoc.littlespaceship.core.domain.component.Attachment;
import dev.luchoc.littlespaceship.core.domain.component.Invulnerable;
import dev.luchoc.littlespaceship.core.domain.component.Pickup;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.component.Shield;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.AttachmentDefinition;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.InvulnerabilitySource;
import java.util.List;
import java.util.Set;

/**
 * Resolves what happens when the player reaches a {@link Pickup}: five fixed power-up kinds, each
 * with its own consumption rule per {@code 03-game-systems.md}, plus the attachment, which is looked
 * up in content instead of being a sixth fixed kind — see {@link #KIND_ATTACHMENT}.
 *
 * <p>Runs at {@code SystemOrder.PICKUP}, after {@code COLLISION}: reading {@link
 * World#collisionHits()} here sees this exact tick's {@link CollisionPair#PICKUP_VS_PLAYER} hits,
 * the same guarantee {@code DamageSystem} already relies on for the pairs it consumes.
 *
 * <p>A pickup already at its cap is never wasted: per {@code 10-mvp-initial-values.md}, it turns
 * into {@link BalanceValues#maxedPickupBonus()} points instead. That bonus is not added to {@link
 * Player#score} directly — it is attached as a {@link ScoreValue} to the pickup entity itself, which
 * is marked for destruction either way, so {@code ScoreSystem}'s ordinary sweep of destroyed,
 * score-carrying entities is what actually credits it. One mechanism for every point scored in the
 * game, not two.
 */
public final class PickupSystem implements GameSystem {

    /** Increases {@link Player#shotLevel} by one, up to {@link BalanceValues#weaponLevels()}. */
    public static final String KIND_WEAPON_UPGRADE = "weapon-upgrade";

    /** Grants a {@link Shield}, if the player does not already have one. */
    public static final String KIND_SHIELD = "shield";

    /** Increases {@link Player#lives} by one, up to {@link BalanceValues#maxLives()}. */
    public static final String KIND_EXTRA_LIFE = "extra-life";

    /** Increases {@link Player#bombs} by one, up to {@link BalanceValues#maxBombs()}. */
    public static final String KIND_BOMB_RECHARGE = "bomb-recharge";

    /**
     * Grants {@link BalanceValues#invulnerabilityPickupDuration()} of grace time, refreshed to that
     * exact duration rather than added to whatever remains — the same "set, not accumulate"
     * semantics {@code DamageSystem} already uses for {@link Invulnerable#remaining}.
     */
    public static final String KIND_INVULNERABILITY = "invulnerability";

    /**
     * Equips an {@link Attachment}, if the player does not already have one. Unlike the five kinds
     * above, {@code "attachment"} is not a fixed rule: {@code Pickup.kind} is looked up directly as
     * an {@link AttachmentDefinition} content id through {@link
     * dev.luchoc.littlespaceship.core.port.ContentSource#attachment(String)}, which is what makes
     * durability data instead of a constant — the MVP's one attachment type happens to use the same
     * string, {@code "attachment"}, as both its kind and its content id, but a second, tougher
     * attachment type would only need a different content id, never a code change here.
     */
    public static final String KIND_ATTACHMENT = "attachment";

    /**
     * Every kind {@link #resolvePickup} recognises, so {@code SpawnSystem} can reject an
     * unrecognised {@code Drop} the moment a wave carrying it spawns, instead of only when a player
     * happens to reach the pickup it eventually produces — see {@link #isRecognisedKind(String)}.
     */
    private static final Set<String> RECOGNISED_KINDS = Set.of(
        KIND_WEAPON_UPGRADE, KIND_SHIELD, KIND_EXTRA_LIFE, KIND_BOMB_RECHARGE,
        KIND_INVULNERABILITY, KIND_ATTACHMENT);

    /**
     * True when {@code kind} is one of the six strings {@link #resolvePickup} would actually accept.
     * A content author's typo in a level's {@code drop} id would otherwise load clean and only crash
     * a running level minutes later, the moment a player reaches the pickup it produced — the exact
     * gap {@code SpawnSystem} closes by calling this before attaching a {@code Drop}.
     *
     * @param kind the content id to check, as it would appear on {@code Drop.pickupId}
     * @return true when a pickup carrying this kind would be resolved, not rejected
     */
    static boolean isRecognisedKind(String kind) {
        return RECOGNISED_KINDS.contains(kind);
    }

    @Override
    public SystemOrder order() {
        return SystemOrder.PICKUP;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        int player = world.playerEntity();
        if (player == EntityId.NONE) {
            return;
        }
        Player state = world.players().get(player);
        if (state == null) {
            return;
        }

        BalanceValues balance = world.content().balance();
        List<CollisionHit> hits = world.collisionHits();
        for (int i = 0; i < hits.size(); i++) {
            CollisionHit hit = hits.get(i);
            if (hit.pair() == CollisionPair.PICKUP_VS_PLAYER && hit.second() == player) {
                resolvePickup(world, balance, player, state, hit.first());
            }
        }
    }

    private static void resolvePickup(
        World world, BalanceValues balance, int player, Player state, int pickupEntity) {
        Pickup pickup = world.pickups().get(pickupEntity);
        if (pickup == null) {
            // A PICKUP-layer collider with no Pickup component is a bug in whoever created it, not
            // something this system should crash the tick over.
            world.markForDestruction(pickupEntity);
            return;
        }

        boolean maxed = switch (pickup.kind) {
            case KIND_WEAPON_UPGRADE -> applyWeaponUpgrade(balance, state);
            case KIND_SHIELD -> applyShield(world, player);
            case KIND_EXTRA_LIFE -> applyExtraLife(balance, state);
            case KIND_BOMB_RECHARGE -> applyBombRecharge(balance, state);
            case KIND_INVULNERABILITY -> applyInvulnerability(world, balance, player);
            case KIND_ATTACHMENT -> applyAttachment(world, player, pickup.kind);
            default -> throw new IllegalArgumentException(
                "pickup " + pickupEntity + " has an unrecognised kind '" + pickup.kind + "'");
        };

        if (maxed) {
            world.scoreValues().set(pickupEntity, new ScoreValue(balance.maxedPickupBonus()));
        }
        world.markForDestruction(pickupEntity);
    }

    /** @return true when the pickup was wasted at the cap and should turn into points instead */
    private static boolean applyWeaponUpgrade(BalanceValues balance, Player state) {
        if (state.shotLevel >= balance.weaponLevels()) {
            return true;
        }
        state.shotLevel++;
        return false;
    }

    private static boolean applyShield(World world, int player) {
        if (world.shields().has(player)) {
            return true;
        }
        world.shields().set(player, new Shield());
        return false;
    }

    private static boolean applyExtraLife(BalanceValues balance, Player state) {
        if (state.lives >= balance.maxLives()) {
            return true;
        }
        state.lives++;
        return false;
    }

    private static boolean applyBombRecharge(BalanceValues balance, Player state) {
        if (state.bombs >= balance.maxBombs()) {
            return true;
        }
        state.bombs++;
        return false;
    }

    private static boolean applyInvulnerability(World world, BalanceValues balance, int player) {
        float duration = balance.invulnerabilityPickupDuration();
        Invulnerable current = world.invulnerabilities().get(player);
        if (current != null && current.remaining >= duration) {
            return true;
        }
        if (current == null) {
            world.invulnerabilities().set(player, new Invulnerable(duration, InvulnerabilitySource.POWERUP));
        } else {
            current.remaining = duration;
            current.source = InvulnerabilitySource.POWERUP;
        }
        return false;
    }

    private static boolean applyAttachment(World world, int player, String kind) {
        if (world.attachments().has(player)) {
            return true;
        }
        AttachmentDefinition definition = world.content().attachment(kind);
        world.attachments().set(player, new Attachment(definition.id(), definition.durability()));
        return false;
    }
}
