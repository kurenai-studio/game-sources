package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.port.BossStatus;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.LevelOutcome;
import dev.luchoc.littlespaceship.core.port.SimpleBossDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleEnemyDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleFormationDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleWaveDefinition;
import dev.luchoc.littlespaceship.core.port.SpawnEvent;
import dev.luchoc.littlespaceship.core.port.WaveEndCondition;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * A full boss encounter run through the real MVP pipeline — {@code Simulation}, every system, the
 * boss included — for phase 07's acceptance criteria: the fight is deterministic and reproducible
 * from a seed, and a replay covers a full victory and a full defeat.
 */
class BossReplayTest {

    private static final String LEVEL = "level-01";
    private static final int TICKS = 400;

    @Test
    @DisplayName("a scripted victory run reproduces the same outcome and score twice")
    void victoryIsDeterministic() {
        String first = fingerprintOf(runVictory());
        String second = fingerprintOf(runVictory());

        assertEquals(first, second);
        assertEquals(LevelOutcome.COMPLETED, runVictory().world().view().outcome());
    }

    @Test
    @DisplayName("a scripted defeat run reproduces the same outcome twice")
    void defeatIsDeterministic() {
        assertEquals(LevelOutcome.DEFEATED, runDefeat().world().view().outcome());
        assertEquals(LevelOutcome.DEFEATED, runDefeat().world().view().outcome());
    }

    /**
     * The roadmap's own example ({@code post-mvp-roadmap.md}, "Tests that assert rules, not only
     * reproducibility"): the ship destroys one of the boss's modules and the world reflects it.
     * {@code BossReplayTest}'s other two tests never touch a module — the victory scenario aims
     * straight at the core, the defeat scenario has no boss at all — so nothing here previously
     * exercised, through the real pipeline, either half of the decided rule. Both halves were decided
     * by phase 07 and are recorded in {@code docs/plan/07-boss/status.md}: the {@code DEFEATED} state
     * is reached on the core's destruction, "whatever keel, pods or arms remain are marked for
     * destruction with it", and a part's "own death alone ends nothing"; the health bar is a sum
     * across every part, "so the bar shortens the instant any part is hit or dies, not only the
     * core". {@code BossSystem}'s and {@link BossStatus}'s javadoc restate them, and are the
     * implementation, not the source. This scripts the player to shoot down the boss's
     * left pod alone, through {@code WeaponSystem}, {@code CollisionSystem}, {@code DamageSystem} and
     * {@code CleanupSystem} exactly as a real run would, and checks both halves at once.
     */
    @Test
    @DisplayName("destroying a pod alone leaves the fight running, and the health bar reflects the loss")
    void destroyingAPodDoesNotEndTheFightAndTheWorldReflectsIt() {
        Simulation simulation = podKillSimulation();
        InputFrame holdFireCentred = new InputFrame(0f, 0f, true, false, false);
        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, holdFireCentred);
        }

        World world = simulation.world();
        BossStatus status = world.view().bossStatus();

        assertEquals(LevelOutcome.IN_PROGRESS, world.view().outcome(),
            "a pod's death alone must not end the fight: the core is the only part that does");
        assertTrue(status.present(), "the boss is still fighting; the health bar must stay shown");
        assertEquals(status.hpMax() - POD_KILL_HEALTH, status.hp(),
            "the health bar must shorten by exactly the destroyed pod's health, no more, no less");
        assertEquals(1, survivingPods(world),
            "one pod was destroyed and removed from the world; its sibling was not");
    }

    /** Hit points the scripted pod in {@link #podKillSimulation()} starts with. */
    private static final int POD_KILL_HEALTH = 30;

    /**
     * The player holds fire, centred on the boss's left pod once it settles at {@code combatY}
     * (core x 104, pod offset −34, nudged 10 units further out to 80 so the shot column clears the
     * left arm's own collider — at x 80 the column sits 20 units from the arm's centre, outside its
     * radius-14 circle even summed with the shot's own radius, while still 10 units from the pod's
     * centre, well inside its radius-12 circle). Core and arm health are set far beyond what {@code
     * TICKS} of sustained fire can deplete, so only the pod ever dies.
     */
    private static Simulation podKillSimulation() {
        TestBalance balance = new TestBalance();
        balance.playerStartX = 80f;
        Simulation simulation = new Simulation(podKillContent(balance), event -> {
        }, 7, LEVEL);
        return simulation;
    }

    private static TestContent podKillContent(TestBalance balance) {
        return new TestContent(balance)
            .withBoss(LEVEL, new SimpleBossDefinition(
                "boss-l1",
                0.2f, // entersAt: soon, so most of the run is the fight itself
                99_999, POD_KILL_HEALTH, 99_999, // core/arm health never depleted; pod dies fast
                5000, 500, 800,
                600f, 60f, // entranceSpeed fast, combatY close to the player
                1000f, // patternCooldown far longer than the run: the boss never attacks back
                100f, 100f))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withEnemy(new SimpleEnemyDefinition("filler", List.of(
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("collider",
                    java.util.Map.of("radius", 3.0f, "fragile", true)),
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("sprite",
                    java.util.Map.of("id", "filler")))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave",
                List.of(new SpawnEvent(10_000f, "filler", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(20_000f)))
            .withSingleWavePlacement(LEVEL, LEVEL + "-wave");
    }

    /** Counts colliders whose radius falls in the pod's own band — {@code BossSystem.POD_RADIUS}. */
    private static int survivingPods(World world) {
        int count = 0;
        for (int i = 0; i < world.colliders().size(); i++) {
            Collider collider = world.colliders().valueAt(i);
            if (collider.radius > 11f && collider.radius < 13f) {
                count++;
            }
        }
        return count;
    }

    /**
     * The player holds fire and stays centred, directly under the boss's core — the only part a
     * level-1-shaped single shot ever reaches — with the boss never attacking back ({@code
     * patternCooldown} far longer than the run), so the outcome depends only on the core's health
     * against sustained weapon fire, both deterministic.
     */
    private static Simulation runVictory() {
        TestBalance balance = new TestBalance();
        Simulation simulation = new Simulation(victoryContent(balance), event -> {
        }, 7, LEVEL);

        InputFrame holdFireCentred = new InputFrame(0f, 0f, true, false, false);
        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, holdFireCentred);
        }
        return simulation;
    }

    /** A single life and a rammer the player never dodges: one hit ends the run. */
    private static Simulation runDefeat() {
        TestBalance balance = new TestBalance();
        balance.initialLives = 1;
        Simulation simulation = new Simulation(defeatContent(balance), event -> {
        }, 7, LEVEL);

        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, InputFrame.IDLE);
        }
        return simulation;
    }

    private static String fingerprintOf(Simulation simulation) {
        World world = simulation.world();
        Player player = world.players().get(world.playerEntity());
        return "outcome=" + world.view().outcome() + " score=" + player.score
            + " lives=" + player.lives;
    }

    private static TestContent victoryContent(TestBalance balance) {
        return new TestContent(balance)
            .withBoss(LEVEL, new SimpleBossDefinition(
                "boss-l1",
                0.2f, // entersAt: soon, so most of the run is the fight itself
                30, 999, 999, // coreHealth low enough to die within TICKS; pods/arms never targeted
                5000, 500, 800,
                600f, 60f, // entranceSpeed fast, combatY close to the player
                1000f, // patternCooldown far longer than the run: the boss never attacks
                100f, 100f))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withEnemy(new SimpleEnemyDefinition("filler", List.of(
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("collider",
                    java.util.Map.of("radius", 3.0f, "fragile", true)),
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("sprite",
                    java.util.Map.of("id", "filler")))))
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave",
                List.of(new SpawnEvent(10_000f, "filler", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(20_000f)))
            .withSingleWavePlacement(LEVEL, LEVEL + "-wave");
    }

    private static TestContent defeatContent(TestBalance balance) {
        return new TestContent(balance)
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withEnemy(new SimpleEnemyDefinition("rammer", List.of(
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("motion",
                    java.util.Map.of("trajectory", "straight-down")),
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("collider",
                    java.util.Map.of("radius", 20.0f, "fragile", true)),
                new dev.luchoc.littlespaceship.core.port.MapComponentSpec("sprite",
                    java.util.Map.of("id", "rammer")))))
            .withTrajectory(new dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition(
                "straight-down", 0f, -100f))
            // Spawned in the same column as the player's own (stationary) start position, with a
            // generous 20-unit radius: descending straight down, it is guaranteed to overlap the
            // player well within TICKS, with no dodging behaviour needed to reach the collision.
            .withWave(new SimpleWaveDefinition(LEVEL + "-wave",
                List.of(new SpawnEvent(
                    0f,
                    "rammer",
                    "single",
                    balance.playerStartX / dev.luchoc.littlespaceship.core.domain.system.MotionSystem.PLAYFIELD_WIDTH,
                    null)),
                new WaveEndCondition.FixedDuration(1f)))
            .withSingleWavePlacement(LEVEL, LEVEL + "-wave");
    }
}
