package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Drop;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Pickup;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.EnemyDestroyed;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import java.util.List;

/**
 * Destroys what was marked and frees identifiers, at the end of the tick and nowhere else.
 *
 * <p>This is the only system that calls {@code World.destroyEntity}. Every other system that decides
 * an entity should die calls {@link World#markForDestruction(int)} instead, which is what lets every
 * system earlier in the pipeline iterate its component stores without an entity vanishing under it
 * mid-tick.
 *
 * <p>It is also where a designed {@link Drop} becomes an actual {@link Pickup} entity: {@link
 * Drop}'s own javadoc says the resolution happens "when the holder is destroyed", and this is the
 * one place every path to destruction converges — ramming, a player projectile, a bomb, whatever
 * comes later — so a drop is honoured the same way regardless of what killed its holder, with no
 * per-source duplication. The spawned pickup only becomes collectable from the next tick's {@code
 * CollisionSystem} pass, which is the correct, unremarkable behaviour of an item appearing where an
 * enemy died.
 *
 * <p>It is also the one place {@link EnemyDestroyed} is emitted, for exactly the same reason: this
 * is the single convergence point for every death source, so an {@code ENEMY}-layer entity is
 * reported destroyed once, uniformly, regardless of whether it was rammed, shot, bombed, or was one
 * of the boss's own parts destroyed alongside its core. An entity on any other layer — a player
 * projectile expiring, a pickup collected, an enemy projectile reaching the player — is not reported:
 * nothing downstream needs those to sound like a kill.
 */
public final class CleanupSystem implements GameSystem {

    @Override
    public SystemOrder order() {
        return SystemOrder.CLEANUP;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        List<Integer> pending = world.pendingDestruction();
        for (int i = 0; i < pending.size(); i++) {
            int entity = pending.get(i);
            spawnDropIfAny(world, entity);
            emitEnemyDestroyedIfAny(world, entity);
            world.destroyEntity(entity);
        }
        pending.clear();
    }

    /**
     * Reads {@code entity}'s {@link Drop} and {@link Transform} before either is wiped out by {@link
     * World#destroyEntity(int)}, and spawns the pickup those describe. Silently does nothing for an
     * entity with no drop, or with a drop but no position to spawn the pickup at — the latter should
     * never happen for a real archetype, since every spawned entity gets a {@code Transform}, but a
     * hand-built test entity might have neither, and that is not this system's failure to report.
     */
    private static void spawnDropIfAny(World world, int entity) {
        Drop drop = world.drops().get(entity);
        if (drop == null) {
            return;
        }
        Transform source = world.transforms().get(entity);
        if (source == null) {
            return;
        }
        createFallingPickup(world, source.x, source.y, drop.pickupId);
    }

    /**
     * Builds the entity a pickup always is — {@code Transform}, {@code Collider}, {@code Sprite},
     * {@code Pickup} and the falling {@code Motion} issue #252 gave every pickup — regardless of
     * whether an enemy's death produced it, here, or content placed it directly through {@link
     * SpawnSystem#update}. Package-private rather than duplicated: the two call sites differ only in
     * where {@code x}/{@code y} and {@code kind} come from, never in what a pickup entity is made of.
     * Carries no {@code WaveOrigin}, on either path — a level's {@code Cleared} end condition must
     * never wait on a pickup the player has no obligation to collect.
     *
     * <p><b>The two call sites do not put the entity in front of {@code CollisionSystem} at the same
     * tick.</b> A dropped pickup is only collectable from the <em>next</em> tick's pass, per this
     * class's own javadoc above — it is created here, at {@code SystemOrder.CLEANUP} (14), after
     * {@code COLLISION} (10) already ran this tick. A placed pickup is created by {@code SpawnSystem}
     * at {@code SystemOrder.SPAWN} (5), before {@code COLLISION} runs, so it is collectable the very
     * same tick it appears — one tick earlier than a dropped pickup at the same position would be.
     * Nobody has decided this difference should exist; it is a direct, unavoidable consequence of the
     * fixed {@link SystemOrder} each path runs at, not a divergence in what this method builds — the
     * entity itself is byte-identical either way. Recorded here because whoever writes the loader or
     * authors content needs to know it, not discover it on screen.
     */
    static void createFallingPickup(World world, float x, float y, String kind) {
        BalanceValues balance = world.content().balance();
        int pickup = world.createEntity();
        world.transforms().set(pickup, new Transform(x, y));
        world.colliders().set(pickup, new Collider(balance.pickupRadius(), CollisionLayer.PICKUP));
        world.sprites().set(pickup, new Sprite(new SpriteId("pickup-" + kind)));
        world.pickups().set(pickup, new Pickup(kind));
        // A pickup falls like everything else the scroll carries past the player (issue #252) — with
        // no Motion it hangs exactly where it entered, reading as pinned to the window rather than
        // part of a moving world. Negative because Transform.y grows upward.
        world.motions().set(pickup, new Motion(0f, -balance.pickupFallSpeed()));
    }

    /**
     * Reads {@code entity}'s {@link Collider} and {@link Transform} before either is wiped out by
     * {@link World#destroyEntity(int)}, and emits {@link EnemyDestroyed} when the layer is {@link
     * CollisionLayer#ENEMY}. Silently does nothing otherwise — a destroyed player projectile, pickup
     * or enemy projectile, or an entity with no collider or no position at all.
     */
    private static void emitEnemyDestroyedIfAny(World world, int entity) {
        Collider collider = world.colliders().get(entity);
        if (collider == null || collider.layer != CollisionLayer.ENEMY) {
            return;
        }
        Transform transform = world.transforms().get(entity);
        if (transform == null) {
            return;
        }
        world.events().emit(new EnemyDestroyed(transform.x, transform.y));
    }
}
