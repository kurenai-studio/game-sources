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
 * The level 1 roster from {@code LevelContentIntegrationTest}, run through the real MVP pipeline
 * with the player firing continuously and weaving across the playfield, for the acceptance
 * criterion in {@code 05-game-systems/plan.md}: "a full-level replay produces the same final score
 * twice". Weapon fire, spawning, collision, damage, drops and pickups all run in the same pass, so
 * this is the broader companion to {@code BombReplayTest}, which isolates the bomb specifically.
 *
 * <p>The tank and the carrier carry the same {@code health} points {@code assets/data/enemies.json}
 * gives them (40 and 80) rather than none, so this is also the one test that exercises {@code
 * Health} at level scale — a fixture that omitted it, as an earlier version of this class did, would
 * never notice a change to that path at all.
 *
 * <p>Unlike {@code DamageReplayTest} (issue #12), this fixture is fully built in-test and fully
 * deterministic, so a committed golden fingerprint costs one constant and turns {@link
 * #levelScoreIsDeterministic()} into a real regression net. Recompute {@link #GOLDEN_FINGERPRINT}
 * deliberately, never to silence a failure without reading why it changed.
 */
class LevelScoreReplayTest {

    private static final String LEVEL = "level-01";
    private static final int TICKS = 900;

    /**
     * Recomputed after issue #84: {@code enemy-rush}'s "dive" trajectory carries it off the bottom of
     * the playfield, where it used to linger forever, uncounted and unscored — the defect #84 fixes.
     * It is now swept by {@code LifetimeSystem}'s safety box once fully off screen, so the entity
     * count drops (12 to 11), but the project owner decided on 28/08/2026 that escaping earns nothing:
     * {@code LifetimeSystem} strips the escaping enemy's {@code ScoreValue} before marking it for
     * destruction, so the score stays exactly what it was before this issue (1350) — only the
     * lingering entity is gone, nothing was credited for it. If this ever needs recomputing again,
     * print {@link #fingerprintOf(Simulation)} from a passing {@link #levelScoreIsDeterministic()} run
     * and paste the result here, deliberately, after reading why it changed.
     */
    private static final String GOLDEN_FINGERPRINT =
        "score=1350 lives=3 bombs=1 shotLevel=1 entities=11";

    @Test
    @DisplayName("a scripted run of the level 1 roster reproduces the same final score twice")
    void levelScoreIsDeterministic() {
        String first = fingerprintOf(run());
        String second = fingerprintOf(run());

        assertEquals(first, second);
        assertEquals(GOLDEN_FINGERPRINT, first);
    }

    @Test
    @DisplayName("the scripted run is not a vacuous pass: it actually scored something")
    void scoredSomething() {
        World world = run().world();
        Player player = world.players().get(world.playerEntity());

        assertTrue(player.score > 0,
            "a run this long, firing continuously, should destroy at least one enemy");
    }

    private static Simulation run() {
        Simulation simulation = new Simulation(levelContent(), event -> {
        }, 5, LEVEL);

        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, scriptedFrame(tick));
        }
        return simulation;
    }

    /** Fires continuously and weaves across the playfield, with an occasional bomb, so weapon fire,
     *  ramming and the bomb all get a chance to contribute score in the same run. */
    private static InputFrame scriptedFrame(int tick) {
        float moveX = ((tick / 13) % 3) - 1f;
        float moveY = ((tick / 17) % 3) - 1f;
        boolean bomb = tick == 400;
        return new InputFrame(moveX * 140f, moveY * 140f, true, false, bomb);
    }

    private static String fingerprintOf(Simulation simulation) {
        World world = simulation.world();
        Player player = world.players().get(world.playerEntity());
        return "score=" + player.score + " lives=" + player.lives + " bombs=" + player.bombs
            + " shotLevel=" + player.shotLevel + " entities=" + world.entityCount();
    }

    private static TestContent levelContent() {
        return new TestContent()
            .withAttachment(new SimpleAttachmentDefinition("attachment", 2))
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
                motion("crawl"), sprite("enemy-tank"), collider(10.5f, false), score(500f),
                health(40f))))
            .withEnemy(new SimpleEnemyDefinition("enemy-carrier", List.of(
                motion("crawl"), sprite("enemy-carrier"), collider(15.0f, false), score(1000f),
                health(80f))))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withFormation(new SimpleFormationDefinition("line-3", List.of(
                new FormationSlot(-20f, 0f), new FormationSlot(0f, 0f), new FormationSlot(20f, 0f))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave", List.of(
                new SpawnEvent(1.0f, "enemy-basic", "line-3", 0.5f, null),
                new SpawnEvent(3.0f, "enemy-light", "single", 0.2f, null),
                new SpawnEvent(5.0f, "enemy-shooter", "single", 0.8f, null),
                new SpawnEvent(7.0f, "enemy-rush", "single", 0.3f, null),
                new SpawnEvent(9.0f, "enemy-tank", "single", 0.5f, "shield"),
                new SpawnEvent(9.5f, "enemy-carrier", "single", 0.6f, "attachment"),
                new SpawnEvent(12.0f, "enemy-basic", "line-3", 0.5f, null)),
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

    private static ComponentSpec health(float points) {
        return new MapComponentSpec("health", Map.of("points", points));
    }
}
