package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.MapComponentSpec;
import dev.luchoc.littlespaceship.core.port.SimpleEnemyDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleFormationDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleWaveDefinition;
import dev.luchoc.littlespaceship.core.port.SpawnEvent;
import dev.luchoc.littlespaceship.core.port.WaveEndCondition;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * The strong encounter — two heavy carriers, each periodically spawning basics — through the real
 * MVP pipeline, for phase 07's addition: {@code SpawnerSystem} is a spawn nested inside a tick that
 * may already contain another spawn ({@code SpawnSystem} placing the carriers themselves), exactly
 * the class of same-tick ordering hazard phase 02's review (finding F4) warned about. This proves the
 * combination stays deterministic end to end, not only in {@code SpawnerSystemTest}'s isolation.
 */
class SpawnerReplayTest {

    private static final String LEVEL = "level-01";
    private static final int TICKS = 400;

    @Test
    @DisplayName("two carriers spawning basics reproduce the same entity count and score twice")
    void twoCarriersSpawningIsDeterministic() {
        assertEquals(fingerprintOf(run()), fingerprintOf(run()));
    }

    @Test
    @DisplayName("the carriers actually produce more entities than the two of them alone")
    void carriersActuallySpawnChildren() {
        World world = run().world();
        // Two carriers plus at least one child each the interval used here guarantees within TICKS.
        assertTrue(world.entityCount() >= 1 /* player */ + 2 /* carriers */ + 2 /* children */);
    }

    private static Simulation run() {
        Simulation simulation = new Simulation(content(), event -> {
        }, 11, LEVEL);
        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, InputFrame.IDLE);
        }
        return simulation;
    }

    private static String fingerprintOf(Simulation simulation) {
        World world = simulation.world();
        return "entities=" + world.entityCount() + " score="
            + world.players().get(world.playerEntity()).score;
    }

    private static TestContent content() {
        return new TestContent()
            .withTrajectory(new SimpleTrajectoryDefinition("crawl", 0f, -9f))
            .withEnemy(new SimpleEnemyDefinition("enemy-basic", List.of(
                sprite("enemy-basic"), collider(5.5f, true))))
            .withEnemy(new SimpleEnemyDefinition("enemy-carrier", List.of(
                motion("crawl"), sprite("enemy-carrier"), collider(15.0f, false),
                new MapComponentSpec("spawner",
                    Map.of("enemyId", "enemy-basic", "interval", 2f, "offsetX", 0f, "offsetY", -20f)))))
            .withFormation(new SimpleFormationDefinition("pair", List.of(
                new FormationSlot(-30f, 0f), new FormationSlot(30f, 0f))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave",
                List.of(new SpawnEvent(0.5f, "enemy-carrier", "pair", 0.5f, "attachment", 0)),
                new WaveEndCondition.FixedDuration(20f)))
            .withSingleWavePlacement(LEVEL, LEVEL + "-wave");
    }

    private static ComponentSpec motion(String trajectory) {
        return new MapComponentSpec("motion", Map.of("trajectory", trajectory));
    }

    private static ComponentSpec sprite(String id) {
        return new MapComponentSpec("sprite", Map.of("id", id));
    }

    private static ComponentSpec collider(float radius, boolean fragile) {
        return new MapComponentSpec("collider", Map.of("radius", radius, "fragile", fragile));
    }
}
