package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.BombState;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.InputFrame;

/**
 * The special attack: on request, spends a bomb charge and clears the on-screen threats an
 * MVP-scale simulation can actually resolve in one tick.
 *
 * <p>Fires on the tick-level rising edge of {@link InputFrame#bomb()}, tracked through {@link
 * BombState}, and not on every tick that reports it held. {@code InputFrame.bomb()}'s own javadoc
 * reads as an edge — "whether the bomb was requested this tick" — but nothing below the simulation
 * actually guarantees that: {@code GameLoop.advance} feeds the very same {@code InputFrame} to every
 * tick of one rendered frame, by design, and an adapter's "just pressed" edge is per render frame,
 * not per tick. Debouncing at the adapter, as an earlier version of this class assumed, has a hole
 * a fixed-step simulation cannot avoid: at a low frame rate, or after {@code GameLoop.MAX_FRAME_TIME}
 * lets a stall catch up, one press produces several ticks, and each of them would have spent a
 * charge. This is the first edge-shaped input the core consumes — {@code fire} is deliberately
 * level-shaped and has no such problem — so the fix belongs here, in the one system that reads
 * {@code bomb()}, rather than in the loop or the adapter, neither of which can know at tick
 * granularity whether a press has already been consumed.
 *
 * <p>Per {@code 02-mvp-functional-spec.md}, a bomb "removes most threats/projectiles on screen and
 * deals heavy damage to resistant enemies". Both halves of that sentence are load-bearing:
 *
 * <ul>
 *   <li><b>On screen.</b> {@link #detonate} skips any candidate whose {@code Transform} falls
 *       outside the playfield. {@code SpawnSystem} places every wave fully off screen at
 *       {@code y = PLAYFIELD_HEIGHT + radius} and above, so without this bound the bomb would reach
 *       through the spawn queue and destroy threats the player has never seen — the opposite of
 *       "on screen" and provable by simulating a real wave and firing the bomb the instant it is
 *       due, which is exactly what {@code BombReplayTest} exercises now.
 *   <li><b>Heavy damage to resistant enemies.</b> Every enemy projectile and every {@link
 *       Collider#fragile} enemy is destroyed outright, the same as by ramming — the bomb is
 *       whole-body impact, so {@code fragile} answers the same question here it does everywhere
 *       else, regardless of any {@code Health} the enemy happens to carry. A non-fragile
 *       ("resistant") enemy instead loses {@link BalanceValues#bombDamage()} hit points through the
 *       shared {@link HealthDamage}, the same mechanism {@code DamageSystem} uses for a player
 *       projectile.
 * </ul>
 *
 * <p>Detonating destroys entities directly through {@link World#markForDestruction(int)} rather than
 * through a {@code CollisionHit}: a bomb's range is the whole visible screen, not a shape two
 * colliders can overlap, so there is nothing for {@code CollisionSystem} to detect in the usual
 * sense. That marking alone would not be enough to protect the player on the same tick, though — see
 * {@code CollisionSystem}'s own javadoc for the rule that closes that gap: an entity already marked
 * for destruction this tick is skipped by collision detection, regardless of what marked it. What
 * happens next to a destroyed enemy — a designed drop, points scored — still goes through the exact
 * same shared pipeline every other death does: {@code CleanupSystem} resolves the drop, {@code
 * ScoreSystem} sweeps the {@code ScoreValue}. Nothing here special-cases the bomb as a source of
 * death.
 */
public final class BombSystem implements GameSystem {

    @Override
    public SystemOrder order() {
        return SystemOrder.BOMB;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        int player = world.playerEntity();
        if (player == EntityId.NONE) {
            return;
        }
        if (!isRisingEdge(world, player, input.bomb())) {
            return;
        }
        Player state = world.players().get(player);
        if (state == null || state.bombs <= 0) {
            return;
        }
        state.bombs--;
        detonate(world, world.content().balance());
    }

    /**
     * True only on the tick {@code held} first becomes true since the last time it was false —
     * recorded in {@link BombState}, created on demand if the player does not already have one.
     * {@link BombState#heldLastTick} is updated on every call regardless of the result, which is
     * what lets a later release-then-press produce a second edge.
     */
    private static boolean isRisingEdge(World world, int player, boolean held) {
        BombState state = world.bombStates().get(player);
        boolean previouslyHeld = state != null && state.heldLastTick;
        if (state == null) {
            world.bombStates().set(player, new BombState(held));
        } else {
            state.heldLastTick = held;
        }
        return held && !previouslyHeld;
    }

    private static void detonate(World world, BalanceValues balance) {
        ComponentStore<Collider> colliders = world.colliders();
        ComponentStore<Transform> transforms = world.transforms();
        for (int i = 0; i < colliders.size(); i++) {
            int entity = colliders.entityAt(i);
            Collider collider = colliders.valueAt(i);
            if (collider.layer != CollisionLayer.ENEMY_PROJECTILE && collider.layer != CollisionLayer.ENEMY) {
                continue;
            }
            Transform transform = transforms.get(entity);
            if (transform == null || !isOnScreen(transform)) {
                continue;
            }
            if (collider.layer == CollisionLayer.ENEMY_PROJECTILE || collider.fragile) {
                world.markForDestruction(entity);
            } else {
                HealthDamage.apply(world, entity, balance.bombDamage());
            }
        }
    }

    /**
     * A candidate counts as on screen when its position — its {@code Transform}, not its collider's
     * edge — falls inside the playfield. A simple, unambiguous rule on purpose: the alternative,
     * letting any part of the collider circle overlap the playfield rectangle, would still count the
     * exact case this bound exists to exclude — a wave just spawned, sitting a fraction of a unit
     * past the edge — as "on screen".
     */
    private static boolean isOnScreen(Transform transform) {
        return transform.x >= 0f && transform.x <= MotionSystem.PLAYFIELD_WIDTH
            && transform.y >= 0f && transform.y <= SpawnSystem.PLAYFIELD_HEIGHT;
    }
}
