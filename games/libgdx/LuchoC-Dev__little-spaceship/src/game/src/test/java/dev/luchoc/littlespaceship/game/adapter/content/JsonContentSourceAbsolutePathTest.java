package dev.luchoc.littlespaceship.game.adapter.content;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.badlogic.gdx.files.FileHandle;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.PathSegment;
import dev.luchoc.littlespaceship.core.port.PathTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.TrajectoryDefinition;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Phase 11j task 1 (issue #287): a {@code path} trajectory's legs may be authored as {@code
 * "waypoints"} — an entry point, then destinations and the speed to reach them, or a {@code "wait"} —
 * instead of {@code "segments"} of {@code {vx, vy, duration}}. The loader turns each leg into the
 * exact same {@link PathSegment} the relative form produces, so every test here either asserts that
 * equivalence directly or exercises one of the failures the syntax's own javadoc argues for.
 *
 * <p>Kept in its own file, separate from {@code JsonContentSourcePathTrajectoryTest}, so a parallel
 * task landing in the same production file does not also collide on the same test file.
 */
final class JsonContentSourceAbsolutePathTest {

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
    void waypointsProduceTheSamePathSegmentAHandWrittenVelocityAndDurationWould() throws IOException {
        // A straight leg from (0, 0) to (30, 40) at speed 10: distance 50, so duration 5, and
        // vx = 30 / 5 = 6, vy = 40 / 5 = 8 — computed by hand to compare against the loader's own
        // arithmetic, rather than trusting it to agree with itself.
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "waypoint-leg",
                  "type": "path",
                  "waypoints": [
                    { "x": 0, "y": 0 },
                    { "x": 30, "y": 40, "speed": 10 }
                  ]
                }
              ]
            }
            """);
        PathTrajectoryDefinition path =
            (PathTrajectoryDefinition) source.trajectory("waypoint-leg");
        assertEquals(1, path.segments().size());
        PathSegment segment = path.segments().get(0);
        assertEquals(6f, segment.vx(), 1e-4f);
        assertEquals(8f, segment.vy(), 1e-4f);
        assertEquals(5f, segment.duration(), 1e-4f);
    }

    @Test
    void waypointsChainFromTheEntryPointThroughEveryDestinationInOrder() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "enter-turn-exit",
                  "type": "path",
                  "waypoints": [
                    { "x": 104, "y": 270 },
                    { "x": 150, "y": 200, "speed": 92 },
                    { "x": 208, "y": 150, "speed": 92 }
                  ]
                }
              ]
            }
            """);
        PathTrajectoryDefinition path =
            (PathTrajectoryDefinition) source.trajectory("enter-turn-exit");
        assertEquals(2, path.segments().size());
        // Second leg starts where the first ends (150, 200), not back at the entry point.
        PathSegment second = path.segments().get(1);
        float expectedDx = 208f - 150f;
        float expectedDy = 150f - 200f;
        float expectedDistance = (float) Math.sqrt(expectedDx * expectedDx + expectedDy * expectedDy);
        float expectedDuration = expectedDistance / 92f;
        assertEquals(expectedDx / expectedDuration, second.vx(), 1e-3f);
        assertEquals(expectedDy / expectedDuration, second.vy(), 1e-3f);
    }

    @Test
    void waitShorthandPausesWithoutMovingTheRunningPosition() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "enter-wait-exit",
                  "type": "path",
                  "waypoints": [
                    { "x": 104, "y": 270 },
                    { "x": 104, "y": 200, "speed": 70 },
                    { "wait": 1.5 },
                    { "x": 208, "y": 150, "speed": 70 }
                  ]
                }
              ]
            }
            """);
        PathTrajectoryDefinition path =
            (PathTrajectoryDefinition) source.trajectory("enter-wait-exit");
        assertEquals(3, path.segments().size());
        PathSegment wait = path.segments().get(1);
        assertEquals(0f, wait.vx());
        assertEquals(0f, wait.vy());
        assertEquals(1.5f, wait.duration());
        // The leg after the wait starts from (104, 200), where the wait left it, not from (0, 0).
        PathSegment afterWait = path.segments().get(2);
        float expectedDx = 208f - 104f;
        float expectedDy = 150f - 200f;
        float expectedDistance = (float) Math.sqrt(expectedDx * expectedDx + expectedDy * expectedDy);
        float expectedDuration = expectedDistance / 70f;
        assertEquals(expectedDx / expectedDuration, afterWait.vx(), 1e-3f);
        assertEquals(expectedDy / expectedDuration, afterWait.vy(), 1e-3f);
    }

    @Test
    void mixingSegmentsAndWaypointsOnOnePathFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "mixed-up",
                      "type": "path",
                      "segments": [ { "vx": 0, "vy": -40, "duration": 1.0 } ],
                      "waypoints": [ { "x": 0, "y": 0 }, { "x": 10, "y": 10, "speed": 5 } ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("mixed-up"), e.getMessage());
    }

    @Test
    void pathTypeWithNeitherSegmentsNorWaypointsFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                { "trajectories": [ { "id": "empty-path", "type": "path" } ] }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("empty-path"), e.getMessage());
    }

    @Test
    void destinationOutsidePlayfieldFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "off-field",
                      "type": "path",
                      "waypoints": [
                        { "x": 104, "y": 270 },
                        { "x": 300, "y": 150, "speed": 90 }
                      ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("off-field"), e.getMessage());
    }

    @Test
    void entryPointOutsidePlayfieldFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "bad-entry",
                      "type": "path",
                      "waypoints": [
                        { "x": -5, "y": 270 },
                        { "x": 100, "y": 150, "speed": 90 }
                      ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("bad-entry"), e.getMessage());
    }

    @Test
    void nonPositiveSpeedFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "zero-speed",
                      "type": "path",
                      "waypoints": [
                        { "x": 104, "y": 270 },
                        { "x": 150, "y": 200, "speed": 0 }
                      ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("zero-speed"), e.getMessage());
    }

    @Test
    void destinationEqualToTheStartFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "stuck",
                      "type": "path",
                      "waypoints": [
                        { "x": 104, "y": 270 },
                        { "x": 104, "y": 270, "speed": 50 }
                      ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("stuck"), e.getMessage());
    }

    @Test
    void onlyOneWaypointFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    { "id": "single-point", "type": "path", "waypoints": [ { "x": 104, "y": 270 } ] }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("single-point"), e.getMessage());
    }

    @Test
    void entryPointWithASpeedFailsAtLoadNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "entry-with-speed",
                      "type": "path",
                      "waypoints": [
                        { "x": 104, "y": 270, "speed": 50 },
                        { "x": 150, "y": 200, "speed": 50 }
                      ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("entry-with-speed"), e.getMessage());
    }

    /**
     * Rule 3 still holds for the absolute form — {@code core}'s own "last segment must have nonzero
     * velocity" refusal, surfaced with this loader's id prefix exactly as it already is for a relative
     * path. Ending an absolute path on a {@code "wait"} is the one way to reach a rest segment through
     * waypoints (a destination leg can never be zero-velocity, since a zero-distance destination is
     * refused above), so this is the deliberate attempt at breaking rule 3 the task asked for, not an
     * incidental case.
     */
    @Test
    void absolutePathEndingOnAWaitFailsCoresRuleThreeNamingFileAndId() {
        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> load("""
                {
                  "trajectories": [
                    {
                      "id": "ends-at-rest",
                      "type": "path",
                      "waypoints": [
                        { "x": 104, "y": 270 },
                        { "x": 150, "y": 200, "speed": 90 },
                        { "wait": 3.0 }
                      ]
                    }
                  ]
                }
                """));
        assertTrue(e.getMessage().contains("trajectories.json"), e.getMessage());
        assertTrue(e.getMessage().contains("ends-at-rest"), e.getMessage());
    }

    @Test
    void mirroringWorksOnAWaypointAuthoredPathToo() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "veer-left-waypoints",
                  "type": "path",
                  "waypoints": [
                    { "x": 104, "y": 270 },
                    { "x": 60, "y": 200, "speed": 80 }
                  ]
                },
                { "id": "veer-right-waypoints", "mirrorOf": "veer-left-waypoints" }
              ]
            }
            """);
        PathTrajectoryDefinition original =
            (PathTrajectoryDefinition) source.trajectory("veer-left-waypoints");
        PathTrajectoryDefinition mirrored =
            (PathTrajectoryDefinition) source.trajectory("veer-right-waypoints");
        assertEquals(-original.segments().get(0).vx(), mirrored.segments().get(0).vx());
        assertEquals(original.segments().get(0).vy(), mirrored.segments().get(0).vy());
        assertEquals(original.segments().get(0).duration(), mirrored.segments().get(0).duration());
    }

    @Test
    void loopStartAndLoopCountStillApplyToWaypointDerivedSegments() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "looping-waypoints",
                  "type": "path",
                  "waypoints": [
                    { "x": 104, "y": 270 },
                    { "x": 150, "y": 240, "speed": 60 },
                    { "x": 104, "y": 210, "speed": 60 },
                    { "x": 60, "y": 180, "speed": 60 }
                  ],
                  "loopStart": 1,
                  "loopCount": 4
                }
              ]
            }
            """);
        TrajectoryDefinition trajectory = source.trajectory("looping-waypoints");
        PathTrajectoryDefinition path = (PathTrajectoryDefinition) trajectory;
        assertEquals(3, path.segments().size());
        assertEquals(1, path.loopStart());
        assertEquals(4, path.loopCount());
    }
}
