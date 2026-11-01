package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Lifetime;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import java.util.ArrayList;
import java.util.List;

/**
 * Expires projectiles and fallen pickups once they leave the playfield, and removes an escaped
 * enemy from the simulation by two independent mechanisms, per the project owner's decision recorded
 * in {@code docs/planning/08-decisions-and-open-items.md} ("The 11 group, 27/08/2026") and closing
 * issue #84.
 *
 * <p><b>Projectiles and pickups</b> are expired by the same position check, with a small {@link
 * #PROJECTILE_MARGIN} past the playfield edge, unchanged from before this issue: a run does not
 * accumulate an unbounded number of them over a level lasting several minutes, and every MVP
 * projectile is a straight line, so "has it left the playfield" is a position check, not a countdown.
 * A pickup joined this check in issue #252, once it started falling with a {@code Motion} of its own
 * — before that it never moved, so it could never leave the playfield unclaimed. A pickup that
 * reaches the bottom uncollected is a reward the player missed, not a leak left for something else to
 * clean up.
 *
 * <p><b>Enemies</b> get two mechanisms, and the rule the whole thing exists to protect is the same
 * for both: neither ever removes an enemy still visible on screen.
 *
 * <ul>
 *   <li>A {@link Lifetime}, data set per archetype rather than a constant in code (the same call
 *       already made for attachment durability). Once {@link Lifetime#remaining} reaches zero the
 *       enemy is removed the moment it is also fully off the playfield — {@link
 *       #isFullyOffPlayfield}, which accounts for the entity's own {@link Collider#radius} so no part
 *       of its sprite is still visible. An enemy still on screen when its lifetime expires simply
 *       keeps existing until it leaves on its own or until the safety box below catches it. {@link
 *       Lifetime} is optional per archetype: an enemy with none relies on the safety box alone.
 *   <li>A <b>safety box</b>, a fixed margin ({@link #SAFETY_MARGIN}) well outside the playfield on
 *       every side, that removes any enemy touching it at once, regardless of whether it carries a
 *       {@link Lifetime}. This is the backstop for whatever a lifetime does not catch — an archetype
 *       with no {@link Lifetime} at all, or a movement shape (phase 11c) that wanders far without its
 *       lifetime ever expiring on screen. Being past the safety box already implies being fully off
 *       the playfield, so this removal never fires on a visible enemy either.
 * </ul>
 *
 * <p><b>The safety box's size is measured against the worst legitimate spawn, not guessed.</b>
 * {@code SpawnSystem.positionSpawned} places a formation's lowest slot at {@code PLAYFIELD_HEIGHT +
 * radius}, and every other slot higher by its own {@code offsetY} spread. Measured against {@code
 * assets/data/formations.json} and {@code assets/data/enemies.json} on 27/08/2026, the worst case is
 * {@code column-3} (a 44-unit vertical spread) carrying {@code enemy-carrier} (the largest radius,
 * 15 units): its top slot is born at {@code y = 270 + 15 + 44 = 329}, {@code 314} measured from its
 * own edge ({@code y - radius}). {@link #SAFETY_MARGIN} is 128 units past every edge — clearing that
 * 314 by 84 units, deliberately more than the 44-unit floor the formations measured on this date
 * demand, since phase 11c adds movement shapes that travel further and must not be eaten by this box
 * on the way out and back in.
 *
 * <p><b>An enemy that escapes by either mechanism gives the player nothing</b> — decided by the
 * project owner on 28/08/2026: score rewards killing, not letting something through. This system is
 * the only thing that has to know that: an escaping enemy has its {@code ScoreValue}, {@code Drop}
 * and {@code Collider} stripped right here, before {@link World#markForDestruction(int)}, so {@code
 * ScoreSystem}, {@code CleanupSystem}'s drop resolution and its {@code EnemyDestroyed} emission — all
 * three already conditional on the component they read being present — simply find nothing to act on.
 * {@code CleanupSystem}'s own "converges every destruction path uniformly, regardless of what killed
 * its holder" stays exactly true: this system does not add a second, source-aware branch to it, it
 * only makes sure an escaped entity no longer carries anything a uniform sweep would find interesting.
 */
public final class LifetimeSystem implements GameSystem {

    /**
     * Extra distance past the playfield edge before a projectile or a fallen pickup is expired, in
     * logical units. Generous on purpose: an entity is destroyed only once every pixel of it, not
     * just its centre, is off screen, so the margin has to clear the largest radius among them — a
     * pickup's {@code pickupRadius} (6 units in {@code balance.json} as of issue #252) is well inside
     * it.
     */
    private static final float PROJECTILE_MARGIN = 16f;

    /**
     * Distance past every playfield edge that removes an enemy outright, regardless of its {@link
     * Lifetime}. See the class javadoc for how this number was measured and why it clears today's
     * worst-case spawn with room to spare for phase 11c's movement shapes.
     */
    static final float SAFETY_MARGIN = 128f;

    @Override
    public SystemOrder order() {
        return SystemOrder.LIFETIME;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        tickLifetimes(world, step);
        expireProjectilesAndPickups(world);
        expireEnemies(world);
    }

    private static void tickLifetimes(World world, float step) {
        ComponentStore<Lifetime> lifetimes = world.lifetimes();
        for (int i = 0; i < lifetimes.size(); i++) {
            lifetimes.valueAt(i).remaining -= step;
        }
    }

    private static void expireProjectilesAndPickups(World world) {
        ComponentStore<Collider> colliders = world.colliders();
        ComponentStore<Transform> transforms = world.transforms();
        for (int i = 0; i < colliders.size(); i++) {
            int entity = colliders.entityAt(i);
            Collider collider = colliders.valueAt(i);
            if (collider.layer != CollisionLayer.PLAYER_PROJECTILE
                && collider.layer != CollisionLayer.ENEMY_PROJECTILE
                && collider.layer != CollisionLayer.PICKUP) {
                continue;
            }
            Transform transform = transforms.get(entity);
            if (transform == null) {
                continue;
            }
            if (isPastProjectileMargin(transform)) {
                world.markForDestruction(entity);
            }
        }
    }

    /**
     * Finds every enemy that has escaped this tick, by either mechanism, in one pass over {@link
     * World#colliders()} — and only then strips and marks them, in a second pass. The two passes are
     * not a style choice: {@link ComponentStore}'s own documentation warns that removing a component
     * from the very store a loop is walking reorders its dense array and skips an element, so {@link
     * #strip} (which removes this entity's {@code Collider}) cannot run while this method is still
     * mid-iteration over that same store.
     */
    private static void expireEnemies(World world) {
        ComponentStore<Collider> colliders = world.colliders();
        ComponentStore<Transform> transforms = world.transforms();
        List<Integer> escaped = new ArrayList<>();
        for (int i = 0; i < colliders.size(); i++) {
            int entity = colliders.entityAt(i);
            Collider collider = colliders.valueAt(i);
            if (collider.layer != CollisionLayer.ENEMY) {
                continue;
            }
            Transform transform = transforms.get(entity);
            if (transform == null) {
                continue;
            }
            if (isPastSafetyBox(transform, collider.radius)) {
                escaped.add(entity);
                continue;
            }
            Lifetime lifetime = world.lifetimes().get(entity);
            if (lifetime != null
                && lifetime.remaining <= 0f
                && isFullyOffPlayfield(transform, collider.radius)) {
                escaped.add(entity);
            }
        }
        for (int i = 0; i < escaped.size(); i++) {
            strip(world, escaped.get(i));
        }
    }

    /**
     * Removes exactly the components that would make this entity's destruction count as a kill —
     * see the class javadoc for why stripping them here is enough, with no change needed anywhere
     * else in the pipeline.
     */
    private static void strip(World world, int entity) {
        world.scoreValues().remove(entity);
        world.drops().remove(entity);
        world.colliders().remove(entity);
        world.markForDestruction(entity);
    }

    private static boolean isPastProjectileMargin(Transform transform) {
        return transform.y < -PROJECTILE_MARGIN
            || transform.y > SpawnSystem.PLAYFIELD_HEIGHT + PROJECTILE_MARGIN
            || transform.x < -PROJECTILE_MARGIN
            || transform.x > MotionSystem.PLAYFIELD_WIDTH + PROJECTILE_MARGIN;
    }

    /**
     * Whether every pixel of {@code transform}'s circle has left the playfield rectangle — the
     * "off screen" the class javadoc promises neither mechanism ever violates.
     */
    private static boolean isFullyOffPlayfield(Transform transform, float radius) {
        return transform.x + radius < 0f
            || transform.x - radius > MotionSystem.PLAYFIELD_WIDTH
            || transform.y + radius < 0f
            || transform.y - radius > SpawnSystem.PLAYFIELD_HEIGHT;
    }

    private static boolean isPastSafetyBox(Transform transform, float radius) {
        return transform.x + radius < -SAFETY_MARGIN
            || transform.x - radius > MotionSystem.PLAYFIELD_WIDTH + SAFETY_MARGIN
            || transform.y + radius < -SAFETY_MARGIN
            || transform.y - radius > SpawnSystem.PLAYFIELD_HEIGHT + SAFETY_MARGIN;
    }
}
