package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.MapComponentSpec;
import dev.luchoc.littlespaceship.core.port.SimpleAttachmentDefinition;
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
 * The bomb reaches into collision, damage, scoring and the drop pipeline within the same tick, all
 * through the real {@code Simulation} pipeline — the shape of scenario {@code 05-game-systems/plan.md}
 * calls out as a better fit for a replay than for unit tests alone.
 *
 * <p>Unlike {@code DamageReplayTest} (issue #12), this fixture is fully built in-test and fully
 * deterministic, so a committed golden fingerprint costs one constant and turns
 * {@link #bombedRunIsDeterministic()} into a real regression net: a refactor that changes the
 * outcome fails here even if both of its own runs still agree with each other. Recompute {@link
 * #GOLDEN_FINGERPRINT} deliberately, never to silence a failure without reading why it changed.
 */
class BombReplayTest {

    private static final String LEVEL = "level-01";
    private static final int TICKS = 600;

    /**
     * Recomputed after the on-screen bound was added to {@code BombSystem}; if this ever needs
     * recomputing again, print {@link #fingerprintOf(Simulation)} from a passing {@link
     * #bombedRunIsDeterministic()} run and paste the result here, deliberately, after reading why it
     * changed.
     */
    private static final String GOLDEN_FINGERPRINT = "score=200 lives=3 bombs=0 entities=4";

    @Test
    @DisplayName("a level with the bomb used repeatedly ends with the same score both times")
    void bombedRunIsDeterministic() {
        String first = fingerprintOf(run());
        String second = fingerprintOf(run());

        assertEquals(first, second);
        assertEquals(GOLDEN_FINGERPRINT, first);
    }

    @Test
    @DisplayName("the bomb actually destroyed something and the run is not a vacuous pass")
    void bombActuallyScoredSomething() {
        Simulation simulation = run();
        Player player = simulation.world().players().get(simulation.world().playerEntity());

        assertTrue(player.score > 0, "at least one fragile enemy should have been cleared and scored");
    }

    private static Simulation run() {
        TestContent content = levelContent();
        Simulation simulation = new Simulation(content, event -> {
        }, 11, LEVEL);

        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, scriptedFrame(tick));
        }
        return simulation;
    }

    /**
     * Bomb requested well after each of the first two waves has both spawned and had time to
     * actually descend onto the playfield — {@code BOMB} runs before {@code SPAWN}, so a request on
     * the exact tick a wave becomes due would still find it fully off screen (wave 1 spawns at
     * {@code y = 275.5}, the {@code crawl} trajectory only descends at 9 units/s, and {@code
     * BombSystem} now skips anything above {@code y = 270}). One press per pulse, exactly one tick
     * long, since {@code BombSystem}'s rising-edge tracking would otherwise only spend the first
     * tick of a longer one anyway. The adapter is what would normally debounce a held key; a test
     * script can just script the discrete requests directly.
     */
    private static InputFrame scriptedFrame(int tick) {
        boolean bomb = tick == 110 || tick == 230;
        return new InputFrame(0f, 0f, false, false, bomb);
    }

    private static String fingerprintOf(Simulation simulation) {
        World world = simulation.world();
        Player player = world.players().get(world.playerEntity());
        return "score=" + player.score + " lives=" + player.lives + " bombs=" + player.bombs
            + " entities=" + world.entityCount();
    }

    private static TestContent levelContent() {
        return new TestContent()
            .withAttachment(new SimpleAttachmentDefinition("attachment", 2))
            .withTrajectory(new SimpleTrajectoryDefinition("crawl", 0f, -9f))
            .withEnemy(new SimpleEnemyDefinition("enemy-basic", List.of(
                motion("crawl"), sprite("enemy-basic"), collider(5.5f, true), score(100f))))
            .withFormation(new SimpleFormationDefinition("single",
                List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave", List.of(
                new SpawnEvent(1f, "enemy-basic", "single", 0.3f, null),
                new SpawnEvent(3f, "enemy-basic", "single", 0.5f, "shield"),
                new SpawnEvent(5f, "enemy-basic", "single", 0.7f, null),
                new SpawnEvent(7f, "enemy-basic", "single", 0.4f, null)),
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

    private static ComponentSpec score(float points) {
        return new MapComponentSpec("scoreValue", Map.of("points", points));
    }
}
