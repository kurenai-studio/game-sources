package dev.luchoc.littlespaceship.game.adapter.content;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.badlogic.gdx.files.FileHandle;
import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.domain.system.MotionSystem;
import dev.luchoc.littlespaceship.core.domain.system.SpawnSystem;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.FormationDefinition;
import dev.luchoc.littlespaceship.core.port.FormationSlot;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Issue #334, the {@code game} half of #330: the loader reads a formation slot's optional {@code
 * "delaySeconds"} and constructs the three-argument {@link FormationSlot}. Kept in its own file for
 * the same reason {@code JsonContentSourceSpeedMultiplierTest} is — a parallel task landing in {@code
 * JsonContentSource} should not also collide on a test file.
 *
 * <p>The quantisation claim is the one worth pinning precisely: {@code TICK_SECONDS} is duplicated
 * here as {@code 1f / 60f} the same way the loader duplicates it, so a test computing "the nearest
 * whole tick" agrees with the loader's own rounding rather than merely re-deriving it.
 */
final class JsonContentSourceFormationDelayTest {

    private static final float TICK_SECONDS = 1f / 60f;

    @TempDir
    Path tempDir;

    private ContentSource load(String formationsJson) throws IOException {
        File dir = tempDir.toFile();
        writeFixedFixtures(dir);
        Files.writeString(tempDir.resolve("formations.json"), formationsJson);
        return new JsonContentSource(new FileHandle(dir), "level-test");
    }

    private static void writeFixedFixtures(File dir) throws IOException {
        Files.writeString(new File(dir, "balance.json").toPath(), """
            {
              "initialLives": 3, "maxLives": 5, "initialBombs": 2, "maxBombs": 3, "weaponLevels": 4,
              "respawnInvulnerability": 2.0, "damageInvulnerability": 1.0, "maxedPickupBonus": 500,
              "playerSpeed": 140, "playerSlowFactor": 0.45, "playerStartX": 104, "playerStartY": 30,
              "weaponFireCooldown": 0.15, "weaponProjectileSpeed": 220, "pickupRadius": 6.0,
              "pickupFallSpeed": 20.0,
              "invulnerabilityPickupDuration": 3.0, "lifeCompletionBonus": 1000,
              "bombCompletionBonus": 300, "weaponProjectileDamage": 10, "bombDamage": 50
            }
            """);
        Files.writeString(new File(dir, "trajectories.json").toPath(), """
            { "trajectories": [ { "id": "base", "vx": 0, "vy": -30 } ] }
            """);
        Files.writeString(new File(dir, "enemies.json").toPath(), """
            {
              "enemies": [
                {
                  "id": "enemy-test",
                  "components": {
                    "motion": { "trajectory": "base" },
                    "sprite": { "id": "enemy-basic" },
                    "collider": { "radius": 5.5, "fragile": true },
                    "scoreValue": { "points": 100 },
                    "health": { "points": 20 }
                  }
                }
              ]
            }
            """);
        Files.writeString(new File(dir, "attachments.json").toPath(), """
            { "attachments": [ { "id": "attachment", "durability": 1 } ] }
            """);
        Files.writeString(new File(dir, "level-test.json").toPath(), """
            { "events": [ { "at": 0, "spawn": "enemy-test", "formation": "single", "atX": 0.5 } ] }
            """);
    }

    /** A slot with no {@code "delaySeconds"} must load to exactly the pre-#330 {@link FormationSlot}. */
    @Test
    void aSlotWithNoDelayKeyProducesZeroDelay() throws IOException {
        ContentSource source = load("""
            { "formations": [ { "id": "single", "slots": [ { "offsetX": 3, "offsetY": -4 } ] } ] }
            """);
        FormationDefinition formation = source.formation("single");
        FormationSlot slot = formation.slots().get(0);
        assertEquals(3f, slot.offsetX());
        assertEquals(-4f, slot.offsetY());
        assertEquals(0f, slot.delaySeconds());
    }

    /**
     * The quantisation decision under test: an authored {@code 0.3} — one of the four values that,
     * summed as {@code step} additions, would otherwise turn active a tick earlier than a whole-tick
     * reading predicts (see the {@code core} fragment for #330/#334) — must load to exactly
     * {@code round(0.3 * 60) * TICK_SECONDS}, i.e. 18 ticks, not to the raw float literal.
     */
    @Test
    void aDecimalDelayIsQuantisedToTheNearestWholeTick() throws IOException {
        ContentSource source = load("""
            {
              "formations": [
                {
                  "id": "single",
                  "slots": [
                    { "offsetX": 0, "offsetY": 0 },
                    { "offsetX": 0, "offsetY": 0, "delaySeconds": 0.3 }
                  ]
                }
              ]
            }
            """);
        List<FormationSlot> slots = source.formation("single").slots();
        assertEquals(0f, slots.get(0).delaySeconds());
        assertEquals(18 * TICK_SECONDS, slots.get(1).delaySeconds());
    }

    /** A delay that is already an exact multiple of the tick round-trips unchanged. */
    @Test
    void aWholeTickDelayIsUnchangedByQuantisation() throws IOException {
        ContentSource source = load("""
            {
              "formations": [
                { "id": "single", "slots": [ { "offsetX": 0, "offsetY": 0, "delaySeconds": 0.2 } ] }
              ]
            }
            """);
        FormationSlot slot = source.formation("single").slots().get(0);
        assertEquals(12 * TICK_SECONDS, slot.delaySeconds());
    }

    /**
     * Issue #337: neither #330 nor #334 ever ran a delay quantised by this loader through a real
     * {@code SpawnSystem}/{@code MotionSystem} pipeline — each half was verified alone, and the defect
     * only showed up where the two meet. This drives that seam directly: an authored {@code
     * delaySeconds} goes through {@code JsonContentSource}'s own quantisation, into a {@link
     * FormationSlot} exactly as a shipped level would produce, then through a real {@code SpawnSystem}
     * spawn and forty-plus real {@code MotionSystem} ticks — no {@code TestContent} fixture standing
     * in for any of it. Covers the flagship {@code 0.3s} example (quantises to 18 ticks, inside the
     * 18-40 failing band) and a delay landing at 280 ticks (inside the 258-300 failing band), the two
     * bands #337 names explicitly.
     */
    @Test
    void aQuantisedDelayTracesTheLeaderExactlyThroughARealSpawnAndMotionPipeline() throws IOException {
        assertLoadedDelayTracesLeaderExactly(0.3f, 18);
        assertLoadedDelayTracesLeaderExactly(280f * TICK_SECONDS, 280);
    }

    /**
     * {@link #load} writes {@code level-test.json} with the legacy flat {@code "events"} list, which
     * only {@link ContentSource#timeline(String)} reads — {@code SpawnSystem} reads {@link
     * ContentSource#placements(String)} instead, per {@code JsonContentSource.loadLevel}'s own
     * javadoc. Driving a real {@code SpawnSystem} through this loader therefore needs the {@code
     * "waves"} shape instead: a {@code waves.json} with one {@code cleared} wave, and a level file
     * that places it. Everything else — {@code balance.json}, {@code trajectories.json}, {@code
     * enemies.json}, {@code attachments.json} — is the same fixture {@link #load} already writes.
     */
    private ContentSource loadForPipeline(String formationsJson) throws IOException {
        File dir = tempDir.toFile();
        writeFixedFixtures(dir);
        Files.writeString(tempDir.resolve("formations.json"), formationsJson);
        Files.writeString(tempDir.resolve("waves.json"), """
            {
              "waves": [
                {
                  "id": "wave-test",
                  "end": { "type": "cleared" },
                  "spawns": [ { "at": 0, "spawn": "enemy-test", "formation": "single", "atX": 0.5 } ]
                }
              ]
            }
            """);
        Files.writeString(tempDir.resolve("level-test.json"), """
            { "waves": [ { "wave": "wave-test", "offset": 0 } ] }
            """);
        return new JsonContentSource(new FileHandle(dir), "level-test");
    }

    private void assertLoadedDelayTracesLeaderExactly(float rawDelaySeconds, int expectedDelayTicks)
        throws IOException {
        ContentSource content = loadForPipeline("""
            {
              "formations": [
                {
                  "id": "single",
                  "slots": [
                    { "offsetX": 0, "offsetY": 0 },
                    { "offsetX": 0, "offsetY": 0, "delaySeconds": %s }
                  ]
                }
              ]
            }
            """.formatted(rawDelaySeconds));
        FormationSlot followerSlot = content.formation("single").slots().get(1);
        assertEquals(expectedDelayTicks * TICK_SECONDS, followerSlot.delaySeconds(),
            "loader's own quantisation should already agree with the expected tick count");

        World world = new World(content, new Rng(1), new GameEventQueue());
        SpawnSystem spawn = new SpawnSystem("level-test");
        MotionSystem motion = new MotionSystem();
        spawn.update(world, TICK_SECONDS, InputFrame.IDLE);
        assertEquals(2, world.entityCount());

        int leader = world.trajectories().entityAt(0);
        int follower = world.trajectories().entityAt(1);

        int ticks = expectedDelayTicks + 20;
        List<float[]> leaderHistory = new ArrayList<>();
        List<float[]> followerHistory = new ArrayList<>();
        for (int t = 0; t < ticks; t++) {
            motion.update(world, TICK_SECONDS, InputFrame.IDLE);
            Transform lt = world.transforms().get(leader);
            Transform ft = world.transforms().get(follower);
            leaderHistory.add(new float[] {lt.x, lt.y});
            followerHistory.add(new float[] {ft.x, ft.y});
        }

        for (int t = expectedDelayTicks; t < ticks; t++) {
            float[] expected = leaderHistory.get(t - expectedDelayTicks);
            float[] actual = followerHistory.get(t);
            assertEquals(expected[0], actual[0],
                "delayTicks=" + expectedDelayTicks + " t=" + t + ": follower should trace the leader"
                    + " exactly N ticks behind, through the real loader and pipeline");
            assertEquals(expected[1], actual[1],
                "delayTicks=" + expectedDelayTicks + " t=" + t + ": follower should trace the leader"
                    + " exactly N ticks behind, through the real loader and pipeline");
        }
    }

    @Test
    void aNegativeDelayFailsAtLoadNamingFileAndFormation() {
        assertFailsNaming("single", "formations.json", """
            {
              "formations": [
                { "id": "single", "slots": [ { "offsetX": 0, "offsetY": 0, "delaySeconds": -0.5 } ] }
              ]
            }
            """);
    }

    @Test
    void anUnrecognisedSlotKeyFailsAtLoadNamingFileAndFormation() {
        assertFailsNaming("single", "formations.json", """
            {
              "formations": [
                { "id": "single", "slots": [ { "offsetX": 0, "offsetY": 0, "delaySeconds": 0.2, "extra": 1 } ] }
              ]
            }
            """);
    }

    private void assertFailsNaming(String expectedFormationId, String expectedFile, String formationsJson) {
        IllegalArgumentException failure =
            assertThrows(IllegalArgumentException.class, () -> load(formationsJson));
        String message = failure.getMessage();
        assertTrue(message.contains(expectedFile), "should name the file, was: " + message);
        assertTrue(message.contains(expectedFormationId), "should name the formation, was: " + message);
    }
}
