package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionHit;
import dev.luchoc.littlespaceship.core.domain.collision.CollisionPair;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Detects overlaps by layer pair, never everything against everything.
 *
 * <p>Four pairs, confirmed in {@code 12-architecture.md}: player projectile × enemy, enemy
 * projectile × player, enemy × player, pickup × player. There is exactly one player, so three of
 * the four pairs resolve it once through {@link World#playerEntity()} — an O(1) lookup — and then
 * walk the other layer once, instead of re-scanning the whole collider store per candidate. Only
 * player projectile × enemy is genuinely many-against-many, so that one stays a naive double
 * comparison: every holder of one layer against every holder of the other, with no spatial
 * structure, which is the confirmed decision in {@code 12-architecture.md}.
 *
 * <p>The naive comparison was measured, but not on this exact shape: {@code
 * docs/planning/11-technical-prototype-results.md} times {@code spikes/web-viability/collisionbench}
 * — a directory deleted on 27/08/2026 and readable at commit {@code 68d002e0560c}, which that
 * document also records —
 * which keeps each layer in its own flat {@code float[]} and compares bullets × enemies plus the two
 * "versus player" pairs against a single point — not four independent {@code ComponentStore} scans.
 * That benchmark is evidence for the decision to stay naive, not a measurement of this class; if the
 * cost of the remaining many-against-many pair ever needs re-checking once real projectile counts
 * exist, it has to be measured against {@code ComponentStore}, not read off that table.
 *
 * <p>The result is not a {@code GameEvent}: it is {@link World#collisionHits()}, cleared and refilled
 * here every tick and read by {@code DamageSystem} right after, within the same tick.
 *
 * <p>An entity already in {@link World#pendingDestruction()} this tick never produces a hit,
 * regardless of what marked it there — {@code BombSystem}, {@code LifetimeSystem}, or anything
 * earlier in the pipeline that calls {@code World.markForDestruction}. Marking does not remove a
 * collider, so without this rule an enemy the bomb just cleared, or a projectile that just expired,
 * would still overlap the player this same tick and cost a shield, the attachment or a life for
 * something that visually and logically already stopped existing. This is what actually makes
 * {@code SystemOrder.BOMB} running before {@code COLLISION} protect the player on the same tick —
 * see that stage's javadoc — and it generalises to every future source of same-tick destruction, not
 * only the bomb.
 */
public final class CollisionSystem implements GameSystem {

    @Override
    public SystemOrder order() {
        return SystemOrder.COLLISION;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        List<CollisionHit> hits = world.collisionHits();
        hits.clear();

        Set<Integer> destroyed = destroyedThisTick(world);

        int player = world.playerEntity();
        Collider playerCollider = null;
        Transform playerTransform = null;
        if (player != EntityId.NONE && !destroyed.contains(player)) {
            playerCollider = world.colliders().get(player);
            playerTransform = world.transforms().get(player);
        }

        detectAgainstPlayer(world, CollisionLayer.ENEMY_PROJECTILE, CollisionPair.ENEMY_PROJECTILE_VS_PLAYER,
            player, playerCollider, playerTransform, destroyed, hits);
        detectAgainstPlayer(world, CollisionLayer.ENEMY, CollisionPair.ENEMY_VS_PLAYER,
            player, playerCollider, playerTransform, destroyed, hits);
        detectAgainstPlayer(world, CollisionLayer.PICKUP, CollisionPair.PICKUP_VS_PLAYER,
            player, playerCollider, playerTransform, destroyed, hits);

        detectPair(world, CollisionLayer.PLAYER_PROJECTILE, CollisionLayer.ENEMY,
            CollisionPair.PLAYER_PROJECTILE_VS_ENEMY, destroyed, hits);
    }

    /**
     * A lookup of what {@link World#pendingDestruction()} holds this tick, built once per update
     * instead of once per candidate. Empty in the ordinary case — nothing was marked before {@code
     * COLLISION} runs unless {@code BOMB} or {@code LIFETIME} did — so the common case allocates
     * nothing beyond the shared empty set.
     */
    private static Set<Integer> destroyedThisTick(World world) {
        List<Integer> pending = world.pendingDestruction();
        if (pending.isEmpty()) {
            return Set.of();
        }
        return new HashSet<>(pending);
    }

    /**
     * Tests every holder of {@code layer} against the single, already-resolved player, instead of
     * re-scanning the collider store to find the player for every candidate. This is what turns the
     * three "versus player" pairs from O(matches × store size) into O(store size).
     */
    private static void detectAgainstPlayer(
        World world, CollisionLayer layer, CollisionPair pair,
        int player, Collider playerCollider, Transform playerTransform,
        Set<Integer> destroyed, List<CollisionHit> hits) {
        if (player == EntityId.NONE || playerCollider == null || playerTransform == null) {
            return;
        }
        ComponentStore<Collider> colliders = world.colliders();
        ComponentStore<Transform> transforms = world.transforms();
        for (int i = 0; i < colliders.size(); i++) {
            int entity = colliders.entityAt(i);
            if (entity == player || destroyed.contains(entity)) {
                continue;
            }
            Collider collider = colliders.valueAt(i);
            if (collider.layer != layer) {
                continue;
            }
            Transform transform = transforms.get(entity);
            if (transform == null) {
                continue;
            }
            if (overlaps(transform, collider, playerTransform, playerCollider)) {
                hits.add(new CollisionHit(entity, player, pair));
            }
        }
    }

    /**
     * The one genuinely many-against-many pair: every holder of {@code layerA} against every holder
     * of {@code layerB}, naively. Reserved for pairs where neither side is the single player.
     */
    private static void detectPair(
        World world, CollisionLayer layerA, CollisionLayer layerB, CollisionPair pair,
        Set<Integer> destroyed, List<CollisionHit> hits) {
        ComponentStore<Collider> colliders = world.colliders();
        ComponentStore<Transform> transforms = world.transforms();
        for (int i = 0; i < colliders.size(); i++) {
            int a = colliders.entityAt(i);
            if (destroyed.contains(a)) {
                continue;
            }
            Collider colliderA = colliders.valueAt(i);
            if (colliderA.layer != layerA) {
                continue;
            }
            Transform transformA = transforms.get(a);
            if (transformA == null) {
                continue;
            }
            for (int j = 0; j < colliders.size(); j++) {
                int b = colliders.entityAt(j);
                if (destroyed.contains(b)) {
                    continue;
                }
                Collider colliderB = colliders.valueAt(j);
                if (colliderB.layer != layerB) {
                    continue;
                }
                Transform transformB = transforms.get(b);
                if (transformB == null) {
                    continue;
                }
                if (overlaps(transformA, colliderA, transformB, colliderB)) {
                    hits.add(new CollisionHit(a, b, pair));
                }
            }
        }
    }

    private static boolean overlaps(Transform a, Collider colliderA, Transform b, Collider colliderB) {
        float dx = a.x - b.x;
        float dy = a.y - b.y;
        float radius = colliderA.radius + colliderB.radius;
        return dx * dx + dy * dy <= radius * radius;
    }
}
