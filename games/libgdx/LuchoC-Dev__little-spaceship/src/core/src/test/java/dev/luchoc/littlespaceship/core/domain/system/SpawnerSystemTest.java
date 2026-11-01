package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Spawner;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.WaveOrigin;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.MapComponentSpec;
import dev.luchoc.littlespaceship.core.port.SimpleEnemyDefinition;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@code SpawnerSystem}, the heavy carrier's periodic spawn, against content built inline — the same
 * reasoning {@code SpawnSystemTest} states for the wave system it mirrors.
 */
class SpawnerSystemTest {

    private static final float STEP = 1f / 60f;

    private final TestContent content = new TestContent()
        .withEnemy(new SimpleEnemyDefinition("enemy-basic", List.of(
            sprite("enemy-basic"), collider(5.5f, true))));
    private final World world = new World(content, new Rng(1), new GameEventQueue());
    private final SpawnerSystem system = new SpawnerSystem();

    @Test
    @DisplayName("a spawner does not fire before its interval has elapsed")
    void doesNotSpawnBeforeInterval() {
        int carrier = carrierAt(50f, 100f, 2f, 0f, 0f);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.entityCount());
        Spawner spawner = world.spawners().get(carrier);
        assertEquals(1f, spawner.timer, 0.0001f);
    }

    @Test
    @DisplayName("a spawner fires once its interval elapses, positioned at the holder plus its offset")
    void spawnsAtHolderPlusOffset() {
        carrierAt(50f, 100f, 2f, -10f, 5f);

        system.update(world, 2f, InputFrame.IDLE);

        assertEquals(2, world.entityCount());
        int child = childEntity(world);
        Transform childTransform = world.transforms().get(child);
        assertEquals(40f, childTransform.x);
        assertEquals(105f, childTransform.y);
    }

    @Test
    @DisplayName("the timer resets to the interval, not to zero, after firing")
    void timerResetsToInterval() {
        int carrier = carrierAt(0f, 0f, 2f, 0f, 0f);

        system.update(world, 2f, InputFrame.IDLE);

        assertEquals(2f, world.spawners().get(carrier).timer, 0.0001f);
    }

    @Test
    @DisplayName("a spawner keeps firing every interval, one child per due tick")
    void spawnsRepeatedly() {
        carrierAt(0f, 0f, 1f, 0f, 0f);

        // 305 ticks at 1/60s is a little over 5s and comfortably short of 6s: five interval
        // boundaries crossed regardless of float summation jitter around the exact 1.0s marks,
        // with no risk of a sixth firing this early.
        for (int i = 0; i < 305; i++) {
            system.update(world, STEP, InputFrame.IDLE);
        }

        assertEquals(5, world.entityCount() - 1);
    }

    @Test
    @DisplayName("two holders due the same tick spawn in their own store's creation order, not by hash")
    void multipleHoldersSpawnInCreationOrder() {
        int first = carrierAt(0f, 0f, 1f, 0f, 0f);
        int second = carrierAt(100f, 0f, 1f, 0f, 0f);

        system.update(world, 1f, InputFrame.IDLE);

        // Both carriers plus both children: four entities, and the children are whichever two
        // entities are neither carrier, created in the same order the carriers themselves were.
        assertEquals(4, world.entityCount());
        int firstChild = -1;
        int secondChild = -1;
        for (int i = 0; i < world.transforms().size(); i++) {
            int entity = world.transforms().entityAt(i);
            if (entity == first || entity == second) {
                continue;
            }
            if (firstChild == -1) {
                firstChild = entity;
            } else {
                secondChild = entity;
            }
        }
        assertTrue(firstChild < secondChild, "the first carrier's child must be created first");
    }

    @Test
    @DisplayName("a holder marked for destruction earlier this tick does not spawn")
    void destroyedHolderDoesNotSpawn() {
        int carrier = carrierAt(0f, 0f, 1f, 0f, 0f);
        world.markForDestruction(carrier);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.entityCount());
    }

    @Test
    @DisplayName("a child inherits the carrier's WaveOrigin, per the carrier-children rule")
    void childInheritsCarriersWaveOrigin() {
        int carrier = carrierAt(0f, 0f, 1f, 0f, 0f);
        world.waveOrigins().set(carrier, new WaveOrigin("wave-7"));

        system.update(world, 1f, InputFrame.IDLE);

        int child = childEntity(world);
        WaveOrigin childOrigin = world.waveOrigins().get(child);
        assertEquals("wave-7", childOrigin.waveId);
    }

    @Test
    @DisplayName("a child of a carrier with no WaveOrigin carries none either")
    void childOfWavelessCarrierCarriesNoWaveOrigin() {
        carrierAt(0f, 0f, 1f, 0f, 0f);

        system.update(world, 1f, InputFrame.IDLE);

        int child = childEntity(world);
        assertEquals(0, world.waveOrigins().size());
        assertEquals(false, world.waveOrigins().has(child));
    }

    @Test
    @DisplayName("an unknown enemy id fails naming that id")
    void unknownEnemyIdFails() {
        int carrier = world.createEntity();
        world.transforms().set(carrier, new Transform(0f, 0f));
        world.spawners().set(carrier, new Spawner("enemy-ghost", 1f, 0f, 0f));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));
        assertTrue(e.getMessage().contains("enemy-ghost"));
    }

    private int carrierAt(float x, float y, float interval, float offsetX, float offsetY) {
        int carrier = world.createEntity();
        world.transforms().set(carrier, new Transform(x, y));
        world.spawners().set(carrier, new Spawner("enemy-basic", interval, offsetX, offsetY));
        return carrier;
    }

    private static int childEntity(World world) {
        for (int i = 0; i < world.transforms().size(); i++) {
            int entity = world.transforms().entityAt(i);
            if (!world.spawners().has(entity)) {
                return entity;
            }
        }
        throw new IllegalStateException("no child entity found");
    }

    private static ComponentSpec sprite(String id) {
        return new MapComponentSpec("sprite", Map.of("id", id));
    }

    private static ComponentSpec collider(float radius, boolean fragile) {
        return new MapComponentSpec("collider", Map.of("radius", radius, "fragile", fragile));
    }
}
