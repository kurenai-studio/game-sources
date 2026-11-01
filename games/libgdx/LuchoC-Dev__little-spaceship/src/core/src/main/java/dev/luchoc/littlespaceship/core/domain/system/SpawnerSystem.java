package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Spawner;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.WaveOrigin;
import dev.luchoc.littlespaceship.core.domain.content.ComponentFactoryRegistry;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.EnemyDefinition;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Ticks down every entity's {@link Spawner} and creates a child the instant one is due — the heavy
 * carrier's "spawns basic enemies periodically" rule from {@code 02-mvp-functional-spec.md}, and the
 * reason the strong encounter (two carriers) reads as sustained pressure rather than two large,
 * stationary targets. See {@link SystemOrder#SPAWNER} for the ordering and determinism reasoning.
 *
 * <p>Stateless, unlike {@code SpawnSystem} and {@code BossSystem}: every carrier's countdown lives on
 * its own {@link Spawner} component, not on this system, so a fresh {@code Simulation} needs no fresh
 * instance of this class the way it does of those two — one {@code SpawnerSystem} serves any number
 * of holders, spawned at any time, including a carrier {@code SpawnSystem} creates on the very tick
 * this system runs right after.
 *
 * <p>Each child is built exactly the way {@code SpawnSystem} builds a wave's entities — every {@link
 * ComponentSpec} of the spawned {@link EnemyDefinition} handed to the same kind of {@link
 * ComponentFactoryRegistry} — except positioned at the holder's own current position plus the
 * spawner's fixed offset, never off-screen: a carrier spawning near itself, wherever it currently is,
 * is the correct behaviour for a companion appearing at a station already on screen, unlike a wave's
 * anchor which always enters from beyond the playfield edge.
 *
 * <p>A child also inherits the holder's {@link WaveOrigin}, when it has one — the carrier-children
 * rule the project owner decided on 28/08/2026, recorded in
 * {@code docs/planning/08-decisions-and-open-items.md}: a wave is not "cleared" until the children
 * its carriers produced are also gone, because that is what the player reads on screen. A holder
 * built outside a wave, such as one a test creates directly, carries no {@link WaveOrigin}, and its
 * children carry none either.
 */
public final class SpawnerSystem implements GameSystem {

    private static final ComponentFactoryRegistry FACTORIES = ComponentFactoryRegistry.withDefaults();

    @Override
    public SystemOrder order() {
        return SystemOrder.SPAWNER;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        Set<Integer> destroyed = destroyedThisTick(world);
        ComponentStore<Spawner> spawners = world.spawners();
        // A plain index walk over the dense array, never a HashMap or a Set: see SystemOrder.SPAWNER
        // for why this is what keeps a tick with several carriers due at once reproducible.
        for (int i = 0; i < spawners.size(); i++) {
            int holder = spawners.entityAt(i);
            if (destroyed.contains(holder)) {
                continue;
            }
            Spawner spawner = spawners.valueAt(i);
            spawner.timer -= step;
            if (spawner.timer > 0f) {
                continue;
            }
            spawner.timer = spawner.interval;
            spawnChild(world, holder, spawner);
        }
    }

    /**
     * A lookup of what {@code World#pendingDestruction()} holds this tick, the same trade
     * {@code CollisionSystem} already makes: empty, allocating nothing, in the ordinary case where
     * nothing earlier in the pipeline marked a holder for destruction this tick.
     */
    private static Set<Integer> destroyedThisTick(World world) {
        List<Integer> pending = world.pendingDestruction();
        if (pending.isEmpty()) {
            return Set.of();
        }
        return new HashSet<>(pending);
    }

    private static void spawnChild(World world, int holder, Spawner spawner) {
        Transform origin = world.transforms().get(holder);
        if (origin == null) {
            // A Spawner with no position to spawn from is a bug in whoever built the holder, not
            // something this system should crash a tick over.
            return;
        }
        EnemyDefinition enemy = world.content().enemy(spawner.enemyId);
        int child = world.createEntity();
        for (ComponentSpec spec : enemy.components()) {
            try {
                FACTORIES.attach(world, child, spec);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException(
                    "spawner on entity " + holder + " spawning '" + enemy.id() + "': " + e.getMessage(), e);
            }
        }
        world.transforms().set(child, new Transform(origin.x + spawner.offsetX, origin.y + spawner.offsetY));
        WaveOrigin wave = world.waveOrigins().get(holder);
        if (wave != null) {
            world.waveOrigins().set(child, wave);
        }
    }
}
