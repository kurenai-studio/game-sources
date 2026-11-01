package dev.luchoc.littlespaceship.game.adapter.content;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.badlogic.gdx.files.FileHandle;
import dev.luchoc.littlespaceship.core.port.ArcTrajectoryDefinition;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.PathSegment;
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
 * Phase 11j task 2 (issue #296): a trajectory may be declared as another one traversed faster, with
 * {@code {"id": ..., "speedOf": <id>, "multiplier": <k>}}. The claim under test is narrow and is the
 * whole point of the feature: <strong>the geometry is identical — same shape, same size — and only
 * the traversal time changes.</strong>
 *
 * <p>The geometry tests deliberately do not recompute the loader's own arithmetic. They trace the
 * curve through {@code core}'s runtime evaluation ({@code horizontalVelocityAt}/{@code
 * verticalVelocityAt}, the accessors {@code MotionSystem} itself reads) and compare the fast
 * trajectory sampled at {@code t / k} against the original sampled at {@code t} — and both against
 * positions worked out by hand from the JSON above them, so a loader that agreed with itself while
 * being wrong would still fail here.
 *
 * <p>Kept in its own file so a parallel task landing in {@code JsonContentSource} does not also
 * collide on a test file, the same reason {@code JsonContentSourceAbsolutePathTest} is separate.
 */
final class JsonContentSourceSpeedMultiplierTest {

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

    /**
     * Integrates a trajectory's velocity through {@code core}'s own evaluation, left-endpoint Euler,
     * returning the position reached after {@code duration} seconds. For a {@code path} — velocity
     * piecewise constant — this is exact whenever every segment boundary falls on a sample boundary,
     * which the fixtures below arrange.
     */
    private static float[] traceTo(TrajectoryDefinition trajectory, float duration, int steps) {
        float dt = duration / steps;
        float x = 0f;
        float y = 0f;
        for (int i = 0; i < steps; i++) {
            float t = i * dt;
            x += trajectory.horizontalVelocityAt(t) * dt;
            y += trajectory.verticalVelocityAt(t) * dt;
        }
        return new float[] {x, y};
    }

    /**
     * The whole claim, on a {@code path}: three legs down, right and down again. By hand from the
     * JSON, the original passes through (0, -60) at t = 2 s, (40, -60) at t = 3 s and ends at
     * (40, -110) at t = 4 s. Doubled, it must pass through the very same three points at t = 1, 1.5
     * and 2 — same corners, same total displacement, half the clock.
     */
    @Test
    void aPathRunFasterTracesTheSameGeometryInAFractionOfTheTime() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "down-right-down",
                  "type": "path",
                  "segments": [
                    { "vx": 0, "vy": -30, "duration": 2 },
                    { "vx": 40, "vy": 0, "duration": 1 },
                    { "vx": 0, "vy": -50, "duration": 1 }
                  ]
                },
                { "id": "down-right-down-fast", "speedOf": "down-right-down", "multiplier": 2 }
              ]
            }
            """);
        TrajectoryDefinition original = source.trajectory("down-right-down");
        TrajectoryDefinition fast = source.trajectory("down-right-down-fast");

        assertTracePosition(original, 2f, 200, 0f, -60f);
        assertTracePosition(original, 3f, 300, 40f, -60f);
        assertTracePosition(original, 4f, 400, 40f, -110f);

        assertTracePosition(fast, 1f, 200, 0f, -60f);
        assertTracePosition(fast, 1.5f, 300, 40f, -60f);
        assertTracePosition(fast, 2f, 400, 40f, -110f);
    }

    private static void assertTracePosition(
        TrajectoryDefinition trajectory, float duration, int steps, float expectedX, float expectedY) {
        float[] position = traceTo(trajectory, duration, steps);
        assertEquals(expectedX, position[0], 1e-3f);
        assertEquals(expectedY, position[1], 1e-3f);
    }

    /**
     * The same claim read structurally rather than traced: every leg keeps its direction and its
     * displacement, and only the clock moves. Written against a hand-computed unit direction, not
     * against the loader's numbers.
     */
    @Test
    void everySegmentKeepsItsDirectionAndDisplacementWhileTheTotalDurationIsDivided()
        throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "diagonal",
                  "type": "path",
                  "segments": [
                    { "vx": 30, "vy": -40, "duration": 2 },
                    { "wait": 1 },
                    { "vx": 0, "vy": -60, "duration": 1 }
                  ]
                },
                { "id": "diagonal-fast", "speedOf": "diagonal", "multiplier": 4 }
              ]
            }
            """);
        PathTrajectoryDefinition fast = (PathTrajectoryDefinition) source.trajectory("diagonal-fast");

        // Leg 1: (30, -40) is 50 long, so its unit direction is (0.6, -0.8) and it covers (60, -80).
        PathSegment first = fast.segments().get(0);
        float speed = (float) Math.sqrt(first.vx() * first.vx() + first.vy() * first.vy());
        assertEquals(0.6f, first.vx() / speed, 1e-4f);
        assertEquals(-0.8f, first.vy() / speed, 1e-4f);
        assertEquals(60f, first.vx() * first.duration(), 1e-3f);
        assertEquals(-80f, first.vy() * first.duration(), 1e-3f);
        assertEquals(0.5f, first.duration(), 1e-4f);

        // A wait stays a wait — zero velocity times anything is still zero — and simply lasts less.
        PathSegment wait = fast.segments().get(1);
        assertEquals(0f, wait.vx());
        assertEquals(0f, wait.vy());
        assertEquals(0.25f, wait.duration(), 1e-4f);

        float total = 0f;
        for (PathSegment segment : fast.segments()) {
            total += segment.duration();
        }
        assertEquals(1f, total, 1e-4f); // the original's 2 + 1 + 1 seconds, divided by four
    }

    /** The multiplier has to work on both authoring forms; this is the absolute one, #287's. */
    @Test
    void aWaypointAuthoredPathCanBeSpedUpToo() throws IOException {
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
                },
                { "id": "waypoint-leg-fast", "speedOf": "waypoint-leg", "multiplier": 2.5 }
              ]
            }
            """);
        // By hand: the leg is 50 long at speed 10, so 5 s at (6, 8); at 2.5x it is the same 50 long
        // leg, walked in 2 s at (15, 20) — the destination is where it always was.
        PathSegment fast = ((PathTrajectoryDefinition) source.trajectory("waypoint-leg-fast"))
            .segments().get(0);
        assertEquals(15f, fast.vx(), 1e-4f);
        assertEquals(20f, fast.vy(), 1e-4f);
        assertEquals(2f, fast.duration(), 1e-4f);
        assertEquals(30f, fast.vx() * fast.duration(), 1e-3f);
        assertEquals(40f, fast.vy() * fast.duration(), 1e-3f);
    }

    /**
     * A {@code constant} traces a ray, so "same geometry" means the same direction: both components
     * scale by the same factor and the ray is unchanged.
     */
    @Test
    void aConstantRunFasterKeepsItsDirection() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                { "id": "base", "vx": 30, "vy": -40 },
                { "id": "base-fast", "speedOf": "base", "multiplier": 3 }
              ]
            }
            """);
        SimpleTrajectoryDefinition fast = (SimpleTrajectoryDefinition) source.trajectory("base-fast");
        assertEquals(90f, fast.vx(), 1e-4f);
        assertEquals(-120f, fast.vy(), 1e-4f);
        // Direction is (0.6, -0.8) for both, computed by hand from 30/50 and -40/50.
        float speed = (float) Math.sqrt(fast.vx() * fast.vx() + fast.vy() * fast.vy());
        assertEquals(0.6f, fast.vx() / speed, 1e-4f);
        assertEquals(-0.8f, fast.vy() / speed, 1e-4f);
        // And the point the original reaches in 3 s, the fast one reaches in 1 s: (90, -120).
        assertTracePosition(source.trajectory("base"), 3f, 300, 90f, -120f);
        assertTracePosition(fast, 1f, 300, 90f, -120f);
    }

    /**
     * An {@code arc} is the one kind where "same shape" is not "scale everything": the parabola is
     * preserved only if {@code ay} takes the square of the multiplier. Checked against the closed
     * form worked out by hand — x = vx·t, y = vy·t + ay·t²/2 — with a tolerance covering
     * left-endpoint Euler's own lag on the accelerating axis (|ay·dt·t / 2| = 0.2 at these numbers).
     */
    @Test
    void anArcRunFasterKeepsItsParabolaAndItsCurvature() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                { "id": "base", "vx": 30, "vy": -40 },
                { "id": "swoop", "type": "arc", "vx": 20, "vy": -40, "ay": -20 },
                { "id": "swoop-fast", "speedOf": "swoop", "multiplier": 2 }
              ]
            }
            """);
        ArcTrajectoryDefinition fast = (ArcTrajectoryDefinition) source.trajectory("swoop-fast");
        assertEquals(40f, fast.vx(), 1e-4f);
        assertEquals(-80f, fast.vy(), 1e-4f);
        assertEquals(-80f, fast.ay(), 1e-4f); // -20 * 2 * 2, not -20 * 2

        // By hand at t = 2 s: x = 40, y = -80 + (-20 * 4 / 2) = -120. The fast arc must be there at 1 s.
        assertTracePosition(source.trajectory("swoop"), 2f, 400, 40f, -120f, 0.5f);
        assertTracePosition(fast, 1f, 400, 40f, -120f, 0.5f);
    }

    private static void assertTracePosition(
        TrajectoryDefinition trajectory, float duration, int steps,
        float expectedX, float expectedY, float delta) {
        float[] position = traceTo(trajectory, duration, steps);
        assertEquals(expectedX, position[0], delta);
        assertEquals(expectedY, position[1], delta);
    }

    /** A loop is a range of the same legs, so speeding the legs up speeds the repeats up with them. */
    @Test
    void aLoopingPathKeepsItsLoopRangeAndRepeatCount() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                {
                  "id": "zigzag",
                  "type": "path",
                  "segments": [
                    { "vx": 0, "vy": -30, "duration": 1 },
                    { "vx": 40, "vy": -10, "duration": 1 },
                    { "vx": -40, "vy": -10, "duration": 1 }
                  ],
                  "loopStart": 1,
                  "loopCount": 3
                },
                { "id": "zigzag-fast", "speedOf": "zigzag", "multiplier": 2 }
              ]
            }
            """);
        PathTrajectoryDefinition fast = (PathTrajectoryDefinition) source.trajectory("zigzag-fast");
        assertEquals(1, fast.loopStart());
        assertEquals(3, fast.loopCount());
        // The original's whole run is 1 + 3 * 2 = 7 s and ends at (0, -30 - 60) = (0, -90);
        // the fast one is there after 3.5 s.
        assertTracePosition(source.trajectory("zigzag"), 7f, 700, 0f, -90f);
        assertTracePosition(fast, 3.5f, 700, 0f, -90f);
    }

    /** Both derivations share one resolution pass, so either may be built on top of the other. */
    @Test
    void aMirrorAndAMultiplierComposeInEitherOrderRegardlessOfDeclarationOrder() throws IOException {
        ContentSource source = load("""
            {
              "trajectories": [
                { "id": "fast-then-mirrored", "mirrorOf": "base-fast" },
                { "id": "base-fast", "speedOf": "base", "multiplier": 2 },
                { "id": "mirrored-then-fast", "speedOf": "base-mirrored", "multiplier": 2 },
                { "id": "base-mirrored", "mirrorOf": "base" },
                { "id": "base", "vx": 30, "vy": -40 }
              ]
            }
            """);
        SimpleTrajectoryDefinition a =
            (SimpleTrajectoryDefinition) source.trajectory("fast-then-mirrored");
        SimpleTrajectoryDefinition b =
            (SimpleTrajectoryDefinition) source.trajectory("mirrored-then-fast");
        assertEquals(-60f, a.vx(), 1e-4f);
        assertEquals(-80f, a.vy(), 1e-4f);
        assertEquals(-60f, b.vx(), 1e-4f);
        assertEquals(-80f, b.vy(), 1e-4f);
    }

    @Test
    void aZeroMultiplierFailsAtLoadNamingFileAndId() {
        assertFailsNaming("bad", """
            {
              "trajectories": [
                { "id": "base", "vx": 0, "vy": -30 },
                { "id": "bad", "speedOf": "base", "multiplier": 0 }
              ]
            }
            """);
    }

    @Test
    void aNegativeMultiplierFailsAtLoadNamingFileAndId() {
        assertFailsNaming("bad", """
            {
              "trajectories": [
                { "id": "base", "vx": 0, "vy": -30 },
                { "id": "bad", "speedOf": "base", "multiplier": -2 }
              ]
            }
            """);
    }

    @Test
    void aNonFiniteMultiplierFailsAtLoadNamingFileAndId() {
        // A literal past float's range parses as infinity rather than failing in the reader, so a
        // stray exponent reaches the loader as a non-finite multiplier.
        assertFailsNaming("bad", """
            {
              "trajectories": [
                { "id": "base", "vx": 0, "vy": -30 },
                { "id": "bad", "speedOf": "base", "multiplier": 1e40 }
              ]
            }
            """);
    }

    @Test
    void aMissingMultiplierFailsAtLoadNamingFileAndId() {
        assertFailsNaming("bad", """
            {
              "trajectories": [
                { "id": "base", "vx": 0, "vy": -30 },
                { "id": "bad", "speedOf": "base" }
              ]
            }
            """);
    }

    @Test
    void aSpeedOfEntryRejectsAnyKeyOtherThanIdSpeedOfAndMultiplier() {
        assertFailsNaming("bad", """
            {
              "trajectories": [
                { "id": "base", "vx": 0, "vy": -30 },
                { "id": "bad", "speedOf": "base", "multiplier": 2, "vx": 999 }
              ]
            }
            """);
    }

    @Test
    void aSpeedOfPointingAtNothingFailsAtLoadNamingFileAndId() {
        assertFailsNaming("does-not-exist", """
            {
              "trajectories": [
                { "id": "base", "vx": 0, "vy": -30 },
                { "id": "orphan", "speedOf": "does-not-exist", "multiplier": 2 }
              ]
            }
            """);
    }

    @Test
    void aDerivationCycleThroughSpeedOfFailsAtLoadNamingFileAndId() {
        assertFailsNaming("a", """
            {
              "trajectories": [
                { "id": "a", "speedOf": "b", "multiplier": 2 },
                { "id": "b", "mirrorOf": "a" }
              ]
            }
            """);
    }

    /**
     * Rule 3 — a path may not end at rest — tried through the new form rather than trusted. A wait
     * multiplied by anything is still a wait, so a path that ends on one is refused whether it is
     * authored directly or reached through {@code "speedOf"}: the derived path goes back through
     * {@code PathTrajectoryDefinition}'s own constructor.
     */
    @Test
    void aMultiplierCannotLaunderAPathThatEndsAtRestPastRule3() {
        assertFailsNaming("ends-at-rest", """
            {
              "trajectories": [
                {
                  "id": "ends-at-rest",
                  "type": "path",
                  "segments": [
                    { "vx": 0, "vy": -30, "duration": 1 },
                    { "wait": 5 }
                  ]
                },
                { "id": "ends-at-rest-fast", "speedOf": "ends-at-rest", "multiplier": 2 }
              ]
            }
            """);
    }

    /**
     * An absurd multiplier pushes a segment out of {@code float}'s range, which {@link PathSegment}
     * refuses — and the failure still names the derived id, not just the arithmetic. It is the
     * <em>velocity</em> that gives way: with these numbers {@code vy * multiplier} is -9e39, which
     * overflows to negative infinity, while {@code duration / multiplier} is 3.33e-39 — subnormal,
     * but not zero. Naming duration here would name a guard that never fires.
     */
    @Test
    void aMultiplierThatPushesASegmentOutOfFloatsRangeFailsNamingTheDerivedId() {
        assertFailsNaming("blink", """
            {
              "trajectories": [
                {
                  "id": "slow",
                  "type": "path",
                  "segments": [ { "vx": 0, "vy": -30, "duration": 1 } ]
                },
                { "id": "blink", "speedOf": "slow", "multiplier": 3e38 }
              ]
            }
            """);
    }

    private void assertFailsNaming(String expectedId, String trajectoriesJson) {
        IllegalArgumentException failure =
            assertThrows(IllegalArgumentException.class, () -> load(trajectoriesJson));
        String message = failure.getMessage();
        assertTrue(message.contains("trajectories.json"), "should name the file, was: " + message);
        assertTrue(message.contains(expectedId), "should name the id, was: " + message);
    }
}
