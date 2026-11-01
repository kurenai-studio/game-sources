package dev.luchoc.littlespaceship.game.adapter.content;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.badlogic.gdx.files.FileHandle;
import dev.luchoc.littlespaceship.core.port.ArcTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.PathTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.SimpleTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.TrajectoryDefinition;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Phase 11i task 2 (issue #264): the loader reads the {@code path} kind {@code core-domain} added in
 * task 1 ({@code PathSegment}, {@code PathTrajectoryDefinition}), and mirrors any of the three kinds
 * at content-load time via a {@code "mirrorOf"} key, per the JSON shape posted on issue #259 and the
 * mechanism argued in {@code TrajectoryDefinition}'s own javadoc.
 *
 * <p>Every test builds a whole minimal content directory rather than calling {@code
 * JsonContentSource}'s private parsing methods directly, per this agent's own memory on {@code
 * ContentSource} needing no {@code Gdx.app} — {@link FileHandle}'s {@code File} constructor and
 * {@code JsonReader.parse(FileHandle)} both run with no display and no backend. This exercises the
 * loader end to end, the same public constructor the game actually calls at startup.
 */
final class JsonContentSourcePathTrajectoryTest {

    @TempDir
    Path tempDir;

    private ContentSource load(String trajectoriesJson) throws IOException {
        File dir = tempDir.toFile();
        writeFixedFixtures(dir);
        Files.writeString(tempDir.resolve("trajectories.json"), trajectoriesJson);
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
        Files.writeString(new File(dir, "formations.json").toPath(), """
            { "formations": [ { "id": "single", "slots": [ { "offsetX": 0, "offsetY": 0 } ] } ] }
            """);
        Files.writeString(new File(dir, "enemies.json").toPath(), """
            {
              "enemies": [
                {
                  "id": "enemy-test",
                  "components": {
                    "motion": { "trajectory": "slow-descent" },
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

    @Test
    void pathTrajectoryLoadsWithTurnWaitAndBoundedLoop() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "enter-turn-wait-loop",
                  "type": "path",
                  "segments": [
                    { "vx": 0, "vy": -40, "duration": 2.0 },
                    { "wait": 1.5 },
                    { "vx": -20, "vy": -10, "duration": 1.0 }
                  ],
                  "loopStart": 2,
                  "loopCount": 3
                }
              ]
            }
            """);
        TrajectoryDefinition trajectory = source.trajectory("enter-turn-wait-loop");
        assertTrue(trajectory instanceof PathTrajectoryDefinition,
            "a 'path' entry must load as PathTrajectoryDefinition, was " + trajectory.getClass());
        PathTrajectoryDefinition path = (PathTrajectoryDefinition) trajectory;
        assertEquals(3, path.segments().size());
        assertEquals(2, path.loopStart());
        assertEquals(3, path.loopCount());

        // Reaches MotionSystem correctly means MotionSystem's own contract — vx()/vy() at t=0 and
        // horizontalVelocityAt/verticalVelocityAt through elapsed time — answers the authored numbers.
        assertEquals(0f, trajectory.vx());
        assertEquals(-40f, trajectory.vy());
        // Inside the wait segment (elapsed 2.5s, between 2.0 and 3.5): velocity is zero.
        assertEquals(0f, trajectory.horizontalVelocityAt(2.5f));
        assertEquals(0f, trajectory.verticalVelocityAt(2.5f));
        // Inside the looped turn segment (elapsed 4.0s: 3.5s prefix, 0.5s into the first loop leg).
        assertEquals(-20f, trajectory.horizontalVelocityAt(4.0f));
        assertEquals(-10f, trajectory.verticalVelocityAt(4.0f));
    }

    @Test
    void waitShorthandTranslatesToAZeroVelocitySegment() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "wait-then-leave",
                  "type": "path",
                  "segments": [
                    { "wait": 5.0 },
                    { "vx": 0, "vy": -50, "duration": 1.0 }
                  ]
                }
              ]
            }
            """);
        PathTrajectoryDefinition path = (PathTrajectoryDefinition) source.trajectory("wait-then-leave");
        assertEquals(0f, path.segments().get(0).vx());
        assertEquals(0f, path.segments().get(0).vy());
        assertEquals(5.0f, path.segments().get(0).duration());
    }

    @Test
    void mirroringComposesFromTheOriginalWithNoSecondDefinition() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "veer-left-path",
                  "type": "path",
                  "segments": [
                    { "vx": -20, "vy": -40, "duration": 2.0 },
                    { "vx": -30, "vy": -10, "duration": 3.0 }
                  ]
                },
                { "id": "veer-right-path", "mirrorOf": "veer-left-path" }
              ]
            }
            """);
        PathTrajectoryDefinition original = (PathTrajectoryDefinition) source.trajectory("veer-left-path");
        PathTrajectoryDefinition mirrored = (PathTrajectoryDefinition) source.trajectory("veer-right-path");

        assertEquals("veer-right-path", mirrored.id());
        assertEquals(original.segments().size(), mirrored.segments().size());
        for (int i = 0; i < original.segments().size(); i++) {
            assertEquals(-original.segments().get(i).vx(), mirrored.segments().get(i).vx());
            assertEquals(original.segments().get(i).vy(), mirrored.segments().get(i).vy());
            assertEquals(original.segments().get(i).duration(), mirrored.segments().get(i).duration());
        }
    }

    @Test
    void mirroringWorksForConstantAndArcKindsToo() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                { "id": "swoop", "vx": -10, "vy": -40 },
                { "id": "swoop-mirror", "mirrorOf": "swoop" },
                { "id": "strike-run", "type": "arc", "vx": 0, "vy": -110, "ay": 27 },
                { "id": "strike-run-mirror", "mirrorOf": "strike-run" }
              ]
            }
            """);
        SimpleTrajectoryDefinition swoop = (SimpleTrajectoryDefinition) source.trajectory("swoop");
        SimpleTrajectoryDefinition swoopMirror = (SimpleTrajectoryDefinition) source.trajectory("swoop-mirror");
        assertEquals(-swoop.vx(), swoopMirror.vx());
        assertEquals(swoop.vy(), swoopMirror.vy());

        ArcTrajectoryDefinition strikeRun = (ArcTrajectoryDefinition) source.trajectory("strike-run");
        ArcTrajectoryDefinition strikeRunMirror =
            (ArcTrajectoryDefinition) source.trajectory("strike-run-mirror");
        assertEquals(-strikeRun.vx(), strikeRunMirror.vx());
        assertEquals(strikeRun.vy(), strikeRunMirror.vy());
        assertEquals(strikeRun.ay(), strikeRunMirror.ay());
    }

    @Test
    void mirrorOfAMirrorResolvesRegardlessOfDeclarationOrder() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                { "id": "c", "mirrorOf": "b" },
                { "id": "b", "mirrorOf": "a" },
                { "id": "a", "vx": -15, "vy": -30 }
              ]
            }
            """);
        SimpleTrajectoryDefinition a = (SimpleTrajectoryDefinition) source.trajectory("a");
        SimpleTrajectoryDefinition b = (SimpleTrajectoryDefinition) source.trajectory("b");
        SimpleTrajectoryDefinition c = (SimpleTrajectoryDefinition) source.trajectory("c");
        assertEquals(-a.vx(), b.vx());
        assertEquals(a.vx(), c.vx());
        assertEquals(a.vy(), c.vy());
    }

    @Test
    void unknownTypeFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                { "trajectories": [ { "id": "bad-one", "type": "helix", "vx": 0, "vy": -1 } ] }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("bad-one"), e.getMessage());
    }

    @Test
    void malformedSegmentFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    { "id": "no-duration", "type": "path",
                      "segments": [ { "vx": 0, "vy": -1 } ] }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("no-duration"), e.getMessage());
    }

    @Test
    void pathThatEndsAtRestFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    { "id": "dead-end", "type": "path",
                      "segments": [
                        { "vx": 0, "vy": -40, "duration": 2.0 },
                        { "wait": 3.0 }
                      ] }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("dead-end"), e.getMessage());
    }

    @Test
    void badMirrorReferenceFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                { "trajectories": [ { "id": "orphan", "mirrorOf": "does-not-exist" } ] }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("does-not-exist"), e.getMessage());
    }

    @Test
    void mirrorCycleFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    { "id": "a", "mirrorOf": "b" },
                    { "id": "b", "mirrorOf": "a" }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().toLowerCase().contains("cycle"), e.getMessage());
    }

    @Test
    void mirrorEntryRejectsAnyKeyOtherThanIdAndMirrorOf() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    { "id": "swoop", "vx": -10, "vy": -40 },
                    { "id": "swoop-mirror", "mirrorOf": "swoop", "vx": 999 }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("vx"), e.getMessage());
    }
}
