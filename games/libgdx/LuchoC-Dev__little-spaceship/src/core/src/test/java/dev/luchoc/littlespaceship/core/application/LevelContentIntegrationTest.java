package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.EnemyDefinition;
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
 * The level 1 roster from {@code docs/design/02-sprite-sizes.md} and
 * {@code docs/planning/10-mvp-initial-values.md}, built inline and run through the real MVP
 * pipeline via {@link Simulation}. This is the acceptance-level proof that six archetypes, reusable
 * trajectories and a formation-driven timeline are expressible from data alone, and that a run never
 * starts with an empty world.
 */
class LevelContentIntegrationTest {

    private static final String LEVEL = "level-01";

    @Test
    @DisplayName("a run starts with the player already in the world")
    void runStartsWithThePlayer() {
        Simulation simulation = new Simulation(minimalContent(), event -> {
        }, 1);
        World world = simulation.world();

        int player = world.playerEntity();
        assertTrue(player != 0, "the player should exist from construction");
        Player state = world.players().get(player);
        assertEquals(3, state.lives);
        Sprite sprite = world.sprites().get(player);
        assertEquals("ship-basic", sprite.id.value());
    }

    @Test
    @DisplayName("the six level 1 archetypes spawn from their timeline, sprite ids matching art")
    void sixArchetypesSpawnFromTheTimeline() {
        TestContent content = levelOneContent();
        Simulation simulation = new Simulation(content, event -> {
        }, 1, LEVEL);

        for (int tick = 0; tick < 600; tick++) {
            simulation.tick(GameLoop.STEP, InputFrame.IDLE);
        }

        World world = simulation.world();
        List<String> spriteIds = new java.util.ArrayList<>();
        for (int i = 0; i < world.sprites().size(); i++) {
            spriteIds.add(world.sprites().valueAt(i).id.value());
        }

        assertTrue(spriteIds.contains("ship-basic"), "the player is still there");
        for (String archetype : List.of("enemy-basic", "enemy-light", "enemy-shooter",
            "enemy-rush", "enemy-tank", "enemy-carrier")) {
            assertTrue(spriteIds.contains(archetype), archetype + " should have spawned");
        }
    }

    @Test
    @DisplayName("a tank placed on the super-fast archetype's trajectory is a data change")
    void tankOnRushTrajectoryIsADataChange() {
        ComponentSpec sharedMotion = new MapComponentSpec("motion", Map.of("trajectory", "dive"));
        EnemyDefinition rush = new SimpleEnemyDefinition("enemy-rush", List.of(
            sharedMotion, sprite("enemy-rush"), collider(4.0f, true), score(250f)));
        EnemyDefinition tankOnRushTrajectory = new SimpleEnemyDefinition("enemy-tank", List.of(
            sharedMotion, sprite("enemy-tank"), collider(10.5f, false), score(500f)));

        TestContent content = minimalContent()
            .withEnemy(rush)
            .withEnemy(tankOnRushTrajectory)
            .withTrajectory(new SimpleTrajectoryDefinition("dive", 0f, -80f))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave", List.of(
                new SpawnEvent(0.5f, "enemy-tank", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(5f)))
            .withSingleWavePlacement(LEVEL, LEVEL + "-wave");

        Simulation simulation = new Simulation(content, event -> {
        }, 1, LEVEL);
        for (int tick = 0; tick < 60; tick++) {
            simulation.tick(GameLoop.STEP, InputFrame.IDLE);
        }

        World world = simulation.world();
        assertEquals(2, world.motions().size(), "player plus the spawned tank");
    }

    /** Content with only what {@code Simulation}'s own spawnPlayer step needs. */
    private static TestContent minimalContent() {
        return new TestContent();
    }

    private static TestContent levelOneContent() {
        return minimalContent()
            .withTrajectory(new SimpleTrajectoryDefinition("slow-descent", 0f, -18f))
            .withTrajectory(new SimpleTrajectoryDefinition("swoop", -10f, -40f))
            .withTrajectory(new SimpleTrajectoryDefinition("dive", 0f, -80f))
            .withTrajectory(new SimpleTrajectoryDefinition("crawl", 0f, -9f))
            .withEnemy(new SimpleEnemyDefinition("enemy-basic", List.of(
                motion("slow-descent"), sprite("enemy-basic"), collider(5.5f, true), score(100f))))
            .withEnemy(new SimpleEnemyDefinition("enemy-light", List.of(
                motion("swoop"), sprite("enemy-light"), collider(4.5f, true), score(150f))))
            .withEnemy(new SimpleEnemyDefinition("enemy-shooter", List.of(
                motion("slow-descent"), sprite("enemy-shooter"), collider(6.5f, true), score(200f))))
            .withEnemy(new SimpleEnemyDefinition("enemy-rush", List.of(
                motion("dive"), sprite("enemy-rush"), collider(4.0f, true), score(250f))))
            .withEnemy(new SimpleEnemyDefinition("enemy-tank", List.of(
                motion("crawl"), sprite("enemy-tank"), collider(10.5f, false), score(500f))))
            .withEnemy(new SimpleEnemyDefinition("enemy-carrier", List.of(
                motion("crawl"), sprite("enemy-carrier"), collider(15.0f, false), score(1000f))))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withFormation(new SimpleFormationDefinition("line-3", List.of(
                new FormationSlot(-20f, 0f), new FormationSlot(0f, 0f), new FormationSlot(20f, 0f))))
            .withFormation(new SimpleFormationDefinition("diagonal", List.of(
                new FormationSlot(-15f, 0f), new FormationSlot(0f, -15f), new FormationSlot(15f, -30f))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave", List.of(
                new SpawnEvent(1.0f, "enemy-basic", "line-3", 0.5f, null),
                new SpawnEvent(3.0f, "enemy-light", "diagonal", 0.2f, null),
                new SpawnEvent(5.0f, "enemy-shooter", "single", 0.8f, null),
                new SpawnEvent(7.0f, "enemy-rush", "single", 0.3f, null),
                new SpawnEvent(9.0f, "enemy-tank", "single", 0.5f, "shield"),
                new SpawnEvent(9.5f, "enemy-carrier", "single", 0.6f, "attachment")),
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
