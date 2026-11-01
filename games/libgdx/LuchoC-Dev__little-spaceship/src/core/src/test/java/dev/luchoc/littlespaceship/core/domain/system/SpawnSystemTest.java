package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.ArcTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.ComponentSpec;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.LevelOutcome;
import dev.luchoc.littlespaceship.core.port.MapComponentSpec;
import dev.luchoc.littlespaceship.core.port.PlacedPickup;
import dev.luchoc.littlespaceship.core.port.SimpleEnemyDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleFormationDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleWaveDefinition;
import dev.luchoc.littlespaceship.core.port.SpawnEvent;
import dev.luchoc.littlespaceship.core.port.WaveEndCondition;
import dev.luchoc.littlespaceship.core.port.WavePlacement;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@code SpawnSystem} against content built inline, never read from a file, per the acceptance
 * criterion that core tests do not need a real content pipeline to prove the system works.
 */
class SpawnSystemTest {

    private static final String LEVEL = "level-01";
    private static final String WAVE = "level-01-wave";

    @Test
    @DisplayName("a wave due this tick spawns, positioned from the anchor and the formation slot")
    void spawnsAWaveWhenItIsDue() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.colliders().size());
        int entity = world.colliders().entityAt(0);
        Transform transform = world.transforms().get(entity);
        Collider collider = world.colliders().get(entity);
        assertEquals(0.5f * MotionSystem.PLAYFIELD_WIDTH, transform.x);
        assertEquals(SpawnSystem.PLAYFIELD_HEIGHT + collider.radius, transform.y);
    }

    @Test
    @DisplayName("a wave not due yet does not spawn")
    void doesNotSpawnBeforeItsTime() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(10f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(0, world.entityCount());
    }

    @Test
    @DisplayName("the cursor only advances, so a wave never spawns twice")
    void neverSpawnsTheSameWaveTwice() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        for (int i = 0; i < 10; i++) {
            system.update(world, 1f, InputFrame.IDLE);
        }

        assertEquals(1, world.entityCount());
    }

    @Test
    @DisplayName("a stalled tick can fire more than one due wave in the same update")
    void oneTickCanFireSeveralWaves() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(
                new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null),
                new SpawnEvent(2f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 5f, InputFrame.IDLE);

        assertEquals(2, world.entityCount());
    }

    @Test
    @DisplayName("a formation with several slots spawns one entity per slot, all from the same wave")
    void formationSpawnsOneEntityPerSlot() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("line-3", List.of(
                new FormationSlot(-10f, 0f), new FormationSlot(0f, 0f), new FormationSlot(10f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "line-3", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(3, world.entityCount());
        float anchorX = 0.5f * MotionSystem.PLAYFIELD_WIDTH;
        List<Float> xs = new java.util.ArrayList<>();
        for (int i = 0; i < world.transforms().size(); i++) {
            xs.add(world.transforms().valueAt(i).x);
        }
        assertTrue(xs.contains(anchorX - 10f));
        assertTrue(xs.contains(anchorX));
        assertTrue(xs.contains(anchorX + 10f));
    }

    @Test
    @DisplayName("a diagonal formation still enters fully off-screen, every slot, not just offsetY 0")
    void diagonalFormationEntersFullyOffScreen() {
        List<FormationSlot> diagonal = List.of(
            new FormationSlot(-15f, 0f), new FormationSlot(0f, -15f), new FormationSlot(15f, -30f));
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("diagonal", diagonal))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "diagonal", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(3, world.entityCount());
        float radius = world.colliders().valueAt(0).radius;
        for (int i = 0; i < world.transforms().size(); i++) {
            float y = world.transforms().valueAt(i).y;
            float bottomEdge = y - radius;
            assertTrue(bottomEdge >= SpawnSystem.PLAYFIELD_HEIGHT,
                "entity " + i + " has its bottom edge at " + bottomEdge
                    + ", inside the visible playfield (below " + SpawnSystem.PLAYFIELD_HEIGHT + ")");
        }
        // The slot with the lowest offsetY (-30) is the one tangent to the edge; every other slot
        // must be strictly further above it, or the guarantee would only hold for one slot.
        float lowestY = Float.POSITIVE_INFINITY;
        for (int i = 0; i < world.transforms().size(); i++) {
            lowestY = Math.min(lowestY, world.transforms().valueAt(i).y);
        }
        assertEquals(SpawnSystem.PLAYFIELD_HEIGHT + radius, lowestY);
    }

    @Test
    @DisplayName("a wave instance marked with a drop attaches it to its single-slot formation")
    void designedDropAttachesToSpawnedEntities() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, "shield")));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.drops().size());
        assertEquals("shield", world.drops().valueAt(0).pickupId);
    }

    @Test
    @DisplayName("a drop on a multi-slot formation attaches to exactly the slot named, not every slot")
    void designedDropAttachesToExactlyOneSlot() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("pair",
                List.of(new FormationSlot(-20f, 0f), new FormationSlot(20f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "pair", 0.5f, "attachment", 1)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(2, world.colliders().size());
        assertEquals(1, world.drops().size());
        int dropped = world.drops().entityAt(0);
        assertEquals(20f + 0.5f * MotionSystem.PLAYFIELD_WIDTH, world.transforms().get(dropped).x);
    }

    @Test
    @DisplayName("a drop naming a slot outside its formation fails at spawn time")
    void dropSlotOutsideFormationFails() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, "shield", 1)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));
        assertTrue(e.getMessage().contains("single"));
    }

    @Test
    @DisplayName("an unrecognised drop id fails the moment the wave spawns, naming the enemy and id")
    void unrecognisedDropIdFailsAtSpawnTime() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, "typo-shiled")));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));

        assertTrue(e.getMessage().contains("enemy-basic"));
        assertTrue(e.getMessage().contains("typo-shiled"));
        // Failing before any entity of the wave is created is what keeps this a load-time-shaped
        // failure rather than a half-spawned wave left behind for something else to trip over.
        assertEquals(0, world.entityCount());
    }

    @Test
    @DisplayName("every one of PickupSystem's six recognised kinds spawns a wave without failing")
    void everyRecognisedKindIsAccepted() {
        for (String kind : List.of(PickupSystem.KIND_WEAPON_UPGRADE, PickupSystem.KIND_SHIELD,
            PickupSystem.KIND_EXTRA_LIFE, PickupSystem.KIND_BOMB_RECHARGE,
            PickupSystem.KIND_INVULNERABILITY, PickupSystem.KIND_ATTACHMENT)) {
            TestContent content = baseContent()
                .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
                .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, kind)));
            World world = worldOf(content);
            SpawnSystem system = new SpawnSystem(LEVEL);

            system.update(world, 1f, InputFrame.IDLE);

            assertEquals(kind, world.drops().valueAt(0).pickupId);
        }
    }

    @Test
    @DisplayName("a wave instance with no drop leaves the spawned entity without one")
    void noDropMeansNoDropComponent() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(0, world.drops().size());
    }

    /**
     * Issue #337: the earlier version of this test only exercised {@code delayTicks} 1 and 12, and
     * both happen to fall outside the two bands — 18-40 and 258-300 — where the old float-crossing
     * design activated a delayed slot one tick early. Sweeping every count in 1..300 is what would
     * have caught it; kept as one range rather than picking a few more "interesting" values, since
     * picking values is exactly the mistake that hid the defect for two tasks in a row.
     */
    @Test
    @DisplayName("a delayed slot traces the leader exactly N ticks behind for every N in 1..300, including the two bands the old float crossing failed")
    void delayedSlotTracesLeaderExactlyForEveryTickCountInSweptRange() {
        for (int delayTicks = 1; delayTicks <= 300; delayTicks++) {
            assertDelayedSlotTracesLeaderExactly(delayTicks);
        }
    }

    /**
     * Shared by the sweep above. Issue #330 — a single-file column: both slots at offsetX 0,
     * offsetY 0, only the delay differs. The leader and the follower start at the exact same position,
     * since a delayed slot's decision is about time ({@code Trajectory#elapsed}/{@code #delayTicks}),
     * never about space.
     */
    private void assertDelayedSlotTracesLeaderExactly(int delayTicks) {
        float step = 1f / 60f;
        float delay = delayTicks * step;
        TestContent content = baseContent()
            .withTrajectory(new ArcTrajectoryDefinition("arc-test", 20f, -80f, 40f))
            .withFormation(new SimpleFormationDefinition("column", List.of(
                new FormationSlot(0f, 0f),
                new FormationSlot(0f, 0f, delay))))
            .withSingleWave(LEVEL, List.of(
                new SpawnEvent(0f, "enemy-basic", "column", 0.5f, null, 0, "arc-test")));
        World world = worldOf(content);
        SpawnSystem spawn = new SpawnSystem(LEVEL);
        MotionSystem motion = new MotionSystem();

        spawn.update(world, step, InputFrame.IDLE);
        assertEquals(2, world.entityCount(), "delayTicks=" + delayTicks);

        // Insertion order into a ComponentStore is dense-packed and append-only (see its own class
        // javadoc), and spawnWave creates entities in slot order — slot 0 (no delay) always lands at
        // index 0, slot 1 (the delayed one) always at index 1. Unlike the pre-#337 design, {@code
        // elapsed} never goes negative, so it can no longer tell the two entities apart.
        int leader = world.trajectories().entityAt(0);
        int follower = world.trajectories().entityAt(1);
        float spawnX = world.transforms().get(leader).x;
        float spawnY = world.transforms().get(leader).y;
        assertEquals(spawnX, world.transforms().get(follower).x,
            "both slots start at the same point, delayTicks=" + delayTicks);
        assertEquals(spawnY, world.transforms().get(follower).y,
            "both slots start at the same point, delayTicks=" + delayTicks);

        int ticks = delayTicks + 40;
        List<float[]> leaderHistory = new java.util.ArrayList<>();
        List<float[]> followerHistory = new java.util.ArrayList<>();
        for (int t = 0; t < ticks; t++) {
            motion.update(world, step, InputFrame.IDLE);
            Transform lt = world.transforms().get(leader);
            Transform ft = world.transforms().get(follower);
            leaderHistory.add(new float[] {lt.x, lt.y});
            followerHistory.add(new float[] {ft.x, ft.y});
        }

        for (int t = 0; t < delayTicks; t++) {
            assertEquals(spawnX, followerHistory.get(t)[0],
                "held still before its own path begins, delayTicks=" + delayTicks + " t=" + t);
            assertEquals(spawnY, followerHistory.get(t)[1],
                "held still before its own path begins, delayTicks=" + delayTicks + " t=" + t);
        }
        for (int t = delayTicks; t < ticks; t++) {
            float[] expected = leaderHistory.get(t - delayTicks);
            float[] actual = followerHistory.get(t);
            assertEquals(expected[0], actual[0],
                "same x the leader had delaySeconds earlier, delayTicks=" + delayTicks + " t=" + t);
            assertEquals(expected[1], actual[1],
                "same y the leader had delaySeconds earlier, delayTicks=" + delayTicks + " t=" + t);
        }
    }

    @Test
    @DisplayName("the same trajectory attaches to two different archetypes from data alone")
    void sameTrajectoryReusedAcrossArchetypes() {
        ComponentSpec sharedMotion = new MapComponentSpec("motion", Map.of("trajectory", "dive"));
        TestContent content = new TestContent()
            .withTrajectory(new SimpleTrajectoryDefinition("dive", 0f, -80f))
            .withEnemy(new SimpleEnemyDefinition("enemy-rush", List.of(
                sharedMotion, spriteSpec("enemy-rush"), colliderSpec(4.0f, true))))
            .withEnemy(new SimpleEnemyDefinition("enemy-tank", List.of(
                sharedMotion, spriteSpec("enemy-tank"), colliderSpec(10.5f, false))))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(1f, "enemy-rush", "single", 0.5f, null),
                new SpawnEvent(2f, "enemy-tank", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(20f)))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 2f, InputFrame.IDLE);

        assertEquals(2, world.motions().size());
        for (int i = 0; i < world.motions().size(); i++) {
            Motion motion = world.motions().valueAt(i);
            assertEquals(0f, motion.vx);
            assertEquals(-80f, motion.vy);
        }
    }

    @Test
    @DisplayName(
        "one archetype enters differently at two points of a level without being two archetypes")
    void oneArchetypeTwoShapesFromOneSpawnEvent() {
        // The phase's own acceptance criterion (docs/plan/11c-movement-shapes/plan.md): "enemy-rush
        // enters differently at second 30 and at second 200 without being two archetypes". Here the
        // archetype's own "motion" spec names "dive", its default; the second spawn event overrides
        // it to "strike-run" — the same content id, "enemy-rush", both times.
        ComponentSpec motion = new MapComponentSpec("motion", Map.of("trajectory", "dive"));
        TestContent content = new TestContent()
            .withTrajectory(new SimpleTrajectoryDefinition("dive", 0f, -80f))
            .withTrajectory(new ArcTrajectoryDefinition("strike-run", 0f, -110f, 27f))
            .withEnemy(new SimpleEnemyDefinition("enemy-rush", List.of(
                motion, spriteSpec("enemy-rush"), colliderSpec(4.0f, true))))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(1f, "enemy-rush", "single", 0.5f, null, 0, null),
                new SpawnEvent(2f, "enemy-rush", "single", 0.5f, null, 0, "strike-run")),
                new WaveEndCondition.FixedDuration(20f)))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);
        assertEquals(1, world.motions().size());
        Motion onDefault = world.motions().valueAt(0);
        assertEquals(-80f, onDefault.vy, "the un-overridden spawn keeps the archetype's own default");

        system.update(world, 1f, InputFrame.IDLE);
        assertEquals(2, world.motions().size());
        boolean sawOverride = false;
        for (int i = 0; i < world.motions().size(); i++) {
            if (world.motions().valueAt(i).vy == -110f) {
                sawOverride = true;
            }
        }
        assertTrue(sawOverride, "the overridden spawn follows strike-run's velocity at elapsed time zero");
    }

    @Test
    @DisplayName("an unknown enemy id in the wave fails naming that id")
    void unknownEnemyIdFailsWithMessage() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-ghost", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));
        assertTrue(e.getMessage().contains("enemy-ghost"));
    }

    @Test
    @DisplayName("a malformed component in an archetype fails naming the archetype and the field")
    void malformedComponentNamesArchetypeAndField() {
        TestContent content = new TestContent()
            .withEnemy(new SimpleEnemyDefinition("enemy-basic",
                List.of(new MapComponentSpec("collider", Map.of()))))
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));
        assertTrue(e.getMessage().contains("enemy-basic"));
        assertTrue(e.getMessage().contains("radius"));
    }

    @Test
    @DisplayName("once every placement is exhausted and the spawned enemy is destroyed, the run completes")
    void completesOnceTheTimelineIsExhaustedAndNothingIsAlive() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition(WAVE,
                List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(1.5f)))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);
        int enemy = world.colliders().entityAt(0);
        world.destroyEntity(enemy);
        // The FixedDuration wave itself must end before the level counts as exhausted, not just the
        // spawn of its last event — otherwise this test would pass even if SpawnSystem forgot to
        // resolve end conditions at all.
        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(LevelOutcome.COMPLETED, world.view().outcome());
    }

    @Test
    @DisplayName("the run is not complete while an enemy the timeline spawned is still alive")
    void notCompleteWhileASpawnedEnemySurvives() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "single", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(LevelOutcome.IN_PROGRESS, world.view().outcome());
    }

    @Test
    @DisplayName("every entity a wave spawns carries a WaveOrigin naming that wave's content id")
    void spawnedEntitiesCarryAWaveOrigin() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("pair",
                List.of(new FormationSlot(-10f, 0f), new FormationSlot(10f, 0f))))
            .withSingleWave(LEVEL, List.of(new SpawnEvent(1f, "enemy-basic", "pair", 0.5f, null)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(2, world.waveOrigins().size());
        String firstWaveId = world.waveOrigins().valueAt(0).waveId;
        assertEquals(WAVE, firstWaveId);
        assertEquals(firstWaveId, world.waveOrigins().valueAt(1).waveId);
    }

    @Test
    @DisplayName("two different placements tag their entities with different wave ids")
    void differentWavesGetDifferentIds() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition("wave-a",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(1f)))
            .withWave(new SimpleWaveDefinition("wave-b",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(1f)))
            .withPlacements(LEVEL, List.of(
                new WavePlacement("wave-a", 0f),
                new WavePlacement("wave-b", 0f)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        // wave-a starts at t=0 and spawns immediately; wave-b is only scheduled once wave-a's own
        // FixedDuration(1s) has elapsed. Two ticks give both waves ample room to have run.
        system.update(world, 1f, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(2, world.waveOrigins().size());
        String first = world.waveOrigins().valueAt(0).waveId;
        String second = world.waveOrigins().valueAt(1).waveId;
        assertTrue(!first.equals(second));
    }

    @Test
    @DisplayName("a FixedDuration wave schedules the next placement exactly at its own end, not before or after")
    void fixedDurationEndsExactlyAtItsOwnDuration() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition("wave-a",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(2f)))
            .withWave(new SimpleWaveDefinition("wave-b",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(2f)))
            .withPlacements(LEVEL, List.of(
                new WavePlacement("wave-a", 0f),
                new WavePlacement("wave-b", 0f)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        // wave-a spawns at t=0 (levelTime 1 after this tick); its FixedDuration(2s) has not yet
        // elapsed, so wave-b must not have started.
        system.update(world, 1f, InputFrame.IDLE);
        assertEquals(1, world.entityCount());

        // levelTime reaches 2s exactly here: wave-a ends and wave-b is scheduled and spawns the
        // very same tick, since its own offset is zero.
        system.update(world, 1f, InputFrame.IDLE);
        assertEquals(2, world.entityCount());
    }

    @Test
    @DisplayName("a Cleared wave does not end while an entity it spawned is still alive")
    void clearedWaveWaitsForEveryEntityToBeGone() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition("wave-a",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.Cleared()))
            .withWave(new SimpleWaveDefinition("wave-b",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(1f)))
            .withPlacements(LEVEL, List.of(
                new WavePlacement("wave-a", 0f),
                new WavePlacement("wave-b", 0f)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);
        assertEquals(1, world.entityCount());

        // wave-a's single entity is still alive: many more ticks must not schedule wave-b.
        for (int i = 0; i < 20; i++) {
            system.update(world, 1f, InputFrame.IDLE);
        }
        assertEquals(1, world.entityCount());

        // Destroying the last entity of wave-a lets it be resolved as cleared on the *next* tick,
        // per SystemOrder.SPAWN's own one-tick-late documentation, and only then is wave-b scheduled.
        int survivor = world.colliders().entityAt(0);
        world.destroyEntity(survivor);
        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.entityCount());
        assertEquals("wave-b", world.waveOrigins().valueAt(0).waveId);
    }

    @Test
    @DisplayName("a negative offset starts wave-b while wave-a is still running, unlike a zero offset")
    void negativeOffsetOverlapsTwoWaves() {
        // wave-a is FixedDuration(4s), so its end (levelTime 4) is known the instant it starts at
        // levelTime 0 — scheduleNext resolves wave-b's placement predictively, right there, rather
        // than waiting for wave-a to actually end. wave-a's own second spawn, at its local time 3s, is
        // deliberately placed after where wave-b starts under the negative offset, so a run that
        // reaches that point without wave-a's second entity proves wave-a genuinely has not ended yet.
        assertEquals(2, entityCountAtLevelTime2(-2f),
            "a -2s offset should start wave-b at levelTime 2, two ticks in, alongside wave-a's own "
                + "still-running first entity");
        assertEquals(1, entityCountAtLevelTime2(0f),
            "a 0s offset should not have started wave-b yet at levelTime 2 — it is only due once "
                + "wave-a's known end (levelTime 4) arrives, unlike the -2s offset above");
    }

    /**
     * Runs two 1-second ticks (to level time 2s) against a level of two {@code FixedDuration(4s)}
     * waves — wave-a first, then wave-b offset by {@code waveBOffsetSeconds} from wave-a's own known
     * end (levelTime 4) — and returns how many entities exist at that point. wave-a's only entity by
     * then is its first spawn (at local time 0); its second (at local time 3) is not due yet, and
     * wave-a's own end condition (local time 4) is nowhere close to true, so any entity beyond that
     * first one can only be wave-b's, started before wave-a ended.
     */
    private static int entityCountAtLevelTime2(float waveBOffsetSeconds) {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition("wave-a",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null),
                    new SpawnEvent(3f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(4f)))
            .withWave(new SimpleWaveDefinition("wave-b",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(4f)))
            .withPlacements(LEVEL, List.of(
                new WavePlacement("wave-a", 0f),
                new WavePlacement("wave-b", waveBOffsetSeconds)));
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);

        return world.entityCount();
    }

    @Test
    @DisplayName("moving a placement earlier in the level changes no other placement's own offset")
    void movingAPlacementEarlierChangesNoOtherOffset() {
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            // wave-x is placed first in both lists below, purely so wave-a is never itself the very
            // first placement of the level in either run: the level's actual first wave starts at
            // level time zero, one tick earlier than SpawnSystem can observe any wave scheduled from
            // another wave's end — an unrelated, tick-quantisation artefact of there being no "tick
            // zero," not a violation of this rule. Anchoring wave-a behind wave-x in both lists keeps
            // that artefact out of the comparison below.
            .withWave(new SimpleWaveDefinition("wave-x",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(1f)))
            .withWave(new SimpleWaveDefinition("wave-a",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(2f)))
            .withWave(new SimpleWaveDefinition("wave-b",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(2f)))
            .withWave(new SimpleWaveDefinition("wave-c",
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                new WaveEndCondition.FixedDuration(3f)));

        // wave-c sits last in one level, moved ahead of wave-x (earlier) in the other; wave-a and
        // wave-b keep their own declared offsets — 0f from whichever precedes them, 4f from wave-a —
        // in both.
        List<WavePlacement> waveCLast = List.of(
            new WavePlacement("wave-x", 0f),
            new WavePlacement("wave-a", 0f),
            new WavePlacement("wave-b", 4f),
            new WavePlacement("wave-c", 0f));
        List<WavePlacement> waveCFirst = List.of(
            new WavePlacement("wave-c", 0f),
            new WavePlacement("wave-x", 0f),
            new WavePlacement("wave-a", 0f),
            new WavePlacement("wave-b", 4f));

        int maxTicks = 30;
        Map<String, Integer> lastTicks = firstSpawnTicks(
            content.withPlacements(LEVEL, waveCLast), maxTicks);
        Map<String, Integer> firstTicks = firstSpawnTicks(
            content.withPlacements(LEVEL, waveCFirst), maxTicks);

        // wave-c moving ahead of wave-x genuinely delays wave-a's own start by wave-c's own
        // duration — otherwise a SpawnSystem that ignored placement order entirely would pass the
        // assertion below for the wrong reason.
        assertTrue(firstTicks.get("wave-a") > lastTicks.get("wave-a"),
            "wave-a should start later once wave-c is placed ahead of it");

        // wave-b's own gap from wave-a — its declared 4f offset plus wave-a's own 2f duration — is
        // unaffected by where wave-c sits: moving wave-c earlier shifts wave-a and wave-b by the
        // same amount, leaving the interval between them exactly as declared.
        int gapWithWaveCLast = lastTicks.get("wave-b") - lastTicks.get("wave-a");
        int gapWithWaveCFirst = firstTicks.get("wave-b") - firstTicks.get("wave-a");
        assertEquals(gapWithWaveCLast, gapWithWaveCFirst);
    }

    /**
     * Runs {@code content}'s {@link #LEVEL} for up to {@code maxTicks} one-second ticks, returning
     * the first tick (1-indexed) each distinct wave id is observed on any spawned entity's {@code
     * WaveOrigin}. A wave id absent from the result never spawned within {@code maxTicks}.
     */
    private static Map<String, Integer> firstSpawnTicks(TestContent content, int maxTicks) {
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);
        Map<String, Integer> firstTick = new java.util.HashMap<>();
        for (int tick = 1; tick <= maxTicks; tick++) {
            system.update(world, 1f, InputFrame.IDLE);
            for (int i = 0; i < world.waveOrigins().size(); i++) {
                firstTick.putIfAbsent(world.waveOrigins().valueAt(i).waveId, tick);
            }
        }
        return firstTick;
    }

    @Test
    @DisplayName("a placed pickup exists at the tick it was scheduled for, at the position it was given")
    void placedPickupExistsAtItsScheduledTimeAndPosition() {
        TestContent content = baseContent()
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(100f, "enemy-basic", "single-unused", 0.5f, null)),
                List.of(new PlacedPickup(1f, PickupSystem.KIND_SHIELD, 0.25f, 0.75f)),
                new WaveEndCondition.FixedDuration(1000f)))
            .withFormation(new SimpleFormationDefinition("single-unused", List.of(new FormationSlot(0f, 0f))))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.pickups().size());
        int entity = world.pickups().entityAt(0);
        assertEquals(PickupSystem.KIND_SHIELD, world.pickups().valueAt(0).kind);
        Transform transform = world.transforms().get(entity);
        assertEquals(0.25f * MotionSystem.PLAYFIELD_WIDTH, transform.x);
        assertEquals(0.75f * SpawnSystem.PLAYFIELD_HEIGHT, transform.y);
    }

    @Test
    @DisplayName("a placed pickup not due yet does not exist")
    void placedPickupNotDueYetDoesNotExist() {
        TestContent content = baseContent()
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(100f, "enemy-basic", "single-unused", 0.5f, null)),
                List.of(new PlacedPickup(10f, PickupSystem.KIND_SHIELD, 0.25f, 0.75f)),
                new WaveEndCondition.FixedDuration(1000f)))
            .withFormation(new SimpleFormationDefinition("single-unused", List.of(new FormationSlot(0f, 0f))))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(0, world.pickups().size());
    }

    @Test
    @DisplayName("a placed pickup with no enemy involved needs no enemy or formation to exist")
    void placedPickupNeedsNoEnemyOrFormation() {
        TestContent content = new TestContent()
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(1000f, "enemy-never-spawns", "formation-never-used", 0.5f, null)),
                List.of(new PlacedPickup(1f, PickupSystem.KIND_EXTRA_LIFE, 0.5f, 0.5f)),
                new WaveEndCondition.FixedDuration(1000f)))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.pickups().size());
    }

    @Test
    @DisplayName("a placed pickup falls like an enemy's dropped one, per issue #252's fix")
    void placedPickupFallsLikeADroppedOne() {
        TestContent content = baseContent()
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(1000f, "enemy-basic", "single-unused", 0.5f, null)),
                List.of(new PlacedPickup(1f, PickupSystem.KIND_SHIELD, 0.5f, 0.5f)),
                new WaveEndCondition.FixedDuration(1000f)))
            .withFormation(new SimpleFormationDefinition("single-unused", List.of(new FormationSlot(0f, 0f))))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.motions().size());
        assertTrue(world.motions().valueAt(0).vy < 0f);
    }

    @Test
    @DisplayName("a placed pickup carries no WaveOrigin, so a Cleared wave never waits on it")
    void placedPickupCarriesNoWaveOrigin() {
        TestContent content = new TestContent()
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(1000f, "enemy-never-spawns", "formation-never-used", 0.5f, null)),
                List.of(new PlacedPickup(0f, PickupSystem.KIND_SHIELD, 0.5f, 0.5f)),
                new WaveEndCondition.Cleared()))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);

        assertEquals(1, world.pickups().size());
        assertEquals(0, world.waveOrigins().size(),
            "a placed pickup with no WaveOrigin lets a Cleared wave end without the player ever "
                + "collecting it");
    }

    @Test
    @DisplayName("a Cleared wave does not end while a placed pickup scheduled later is still pending")
    void clearedWaveWaitsForAPendingPlacedPickup() {
        // One spawn at local time 0, destroyed on the second tick — every entity the wave itself
        // spawned is gone well before the pickup, scheduled at local time 30s, is due. A Cleared
        // wave must not resolve on entity-clearance alone while its own pickup cursor still has
        // pickups left to place, the same structural guard spawns() already gets from cursor.
        TestContent content = baseContent()
            .withFormation(new SimpleFormationDefinition("single", List.of(new FormationSlot(0f, 0f))))
            .withWave(new SimpleWaveDefinition(WAVE,
                List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null)),
                List.of(new PlacedPickup(30f, PickupSystem.KIND_SHIELD, 0.5f, 0.5f)),
                new WaveEndCondition.Cleared()))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        system.update(world, 1f, InputFrame.IDLE);
        int enemy = world.colliders().entityAt(0);
        world.destroyEntity(enemy);

        // Forty more one-second ticks reach local time 41s, well past the pickup's own 30s — every
        // enemy the wave spawned has been gone since tick 2, but the pickup must still appear.
        for (int i = 0; i < 40; i++) {
            system.update(world, 1f, InputFrame.IDLE);
        }

        assertEquals(1, world.pickups().size(),
            "the placed pickup at 30s must still spawn even though the wave's own entities cleared "
                + "well before it was due");
    }

    @Test
    @DisplayName("an unrecognised placed pickup kind fails naming the wave and the timestamp")
    void unrecognisedPlacedPickupKindFailsWithMessage() {
        TestContent content = new TestContent()
            .withWave(new SimpleWaveDefinition(WAVE, List.of(
                new SpawnEvent(1000f, "enemy-never-spawns", "formation-never-used", 0.5f, null)),
                List.of(new PlacedPickup(1f, "typo-shiled", 0.5f, 0.5f)),
                new WaveEndCondition.FixedDuration(1000f)))
            .withSingleWavePlacement(LEVEL, WAVE);
        World world = worldOf(content);
        SpawnSystem system = new SpawnSystem(LEVEL);

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> system.update(world, 1f, InputFrame.IDLE));

        assertTrue(e.getMessage().contains(WAVE));
        assertTrue(e.getMessage().contains("typo-shiled"));
        assertEquals(0, world.pickups().size());
    }

    @Test
    @DisplayName("rejects being built without a level id")
    void rejectsMissingLevelId() {
        assertThrows(IllegalArgumentException.class, () -> new SpawnSystem(null));
        assertThrows(IllegalArgumentException.class, () -> new SpawnSystem(""));
    }

    private static TestContent baseContent() {
        return new TestContent()
            .withEnemy(new SimpleEnemyDefinition("enemy-basic", List.of(
                spriteSpec("enemy-basic"), colliderSpec(5.5f, true), scoreSpec(100f))));
    }

    private static ComponentSpec spriteSpec(String id) {
        return new MapComponentSpec("sprite", Map.of("id", id));
    }

    private static ComponentSpec colliderSpec(float radius, boolean fragile) {
        return new MapComponentSpec("collider", Map.of("radius", radius, "fragile", fragile));
    }

    private static ComponentSpec scoreSpec(float points) {
        return new MapComponentSpec("scoreValue", Map.of("points", points));
    }

    private static World worldOf(TestContent content) {
        return new World(content, new Rng(1), new GameEventQueue());
    }
}
