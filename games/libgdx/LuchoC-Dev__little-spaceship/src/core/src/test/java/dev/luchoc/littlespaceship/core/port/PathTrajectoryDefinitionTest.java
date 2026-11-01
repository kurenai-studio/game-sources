package dev.luchoc.littlespaceship.core.port;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class PathTrajectoryDefinitionTest {

    @Test
    @DisplayName("a path with a turn is a segment list, and vx/vy read the first segment")
    void firstSegmentAnswersVxAndVy() {
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("enter-and-turn", List.of(
            new PathSegment(0f, -40f, 2f),
            new PathSegment(-30f, 0f, 3f)));

        assertEquals(0f, path.vx());
        assertEquals(-40f, path.vy());
    }

    @Test
    @DisplayName("elapsed time inside the first segment evaluates to the first segment's velocity")
    void withinFirstSegment() {
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("enter-and-turn", List.of(
            new PathSegment(0f, -40f, 2f),
            new PathSegment(-30f, 0f, 3f)));

        assertEquals(0f, path.horizontalVelocityAt(1f));
        assertEquals(-40f, path.verticalVelocityAt(1f));
    }

    @Test
    @DisplayName("a turn: elapsed time past the first segment's duration evaluates to the second segment")
    void pastFirstSegmentTurns() {
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("enter-and-turn", List.of(
            new PathSegment(0f, -40f, 2f),
            new PathSegment(-30f, 0f, 3f)));

        assertEquals(-30f, path.horizontalVelocityAt(2.5f));
        assertEquals(0f, path.verticalVelocityAt(2.5f));
    }

    @Test
    @DisplayName("elapsed time past the whole path holds the last segment's velocity")
    void pastTheWholePathExtrapolatesTheLastSegment() {
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("enter-and-turn", List.of(
            new PathSegment(0f, -40f, 2f),
            new PathSegment(-30f, 0f, 3f)));

        assertEquals(-30f, path.horizontalVelocityAt(100f));
        assertEquals(0f, path.verticalVelocityAt(100f));
    }

    @Test
    @DisplayName("a wait is a zero-velocity segment: velocity is zero for its whole duration")
    void aWaitIsAZeroVelocitySegment() {
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("descend-wait-leave", List.of(
            new PathSegment(0f, -40f, 1f),
            new PathSegment(0f, 0f, 2f),
            new PathSegment(0f, -40f, 1f)));

        assertEquals(0f, path.horizontalVelocityAt(2f));
        assertEquals(0f, path.verticalVelocityAt(2f));
        // Right after the wait ends, the third segment's velocity applies.
        assertEquals(-40f, path.verticalVelocityAt(3.5f));
    }

    @Test
    @DisplayName("a bounded loop repeats its range exactly loopCount times, then holds the last segment")
    void boundedLoopRepeatsThenExtrapolates() {
        // Loop range is index 1 only (one segment, 1 second, vx -20), repeated 3 times.
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("enter-then-loop", List.of(
            new PathSegment(0f, -40f, 1f),
            new PathSegment(-20f, 0f, 1f)),
            1, 3);

        // Prefix (segment 0) lasts 1s. The loop then plays 3 * 1s = 3s, ending at elapsed = 4s.
        assertEquals(-20f, path.horizontalVelocityAt(1.5f), "first pass through the loop");
        assertEquals(-20f, path.horizontalVelocityAt(2.5f), "second pass through the loop");
        assertEquals(-20f, path.horizontalVelocityAt(3.5f), "third and last pass through the loop");
        // Past the loop's bound, the last segment's velocity is held rather than looping a fourth time.
        assertEquals(-20f, path.horizontalVelocityAt(10f));
        assertEquals(0f, path.verticalVelocityAt(10f));
    }

    @Test
    @DisplayName("a permanent-looking loop is just a large bounded count, not a fourth case")
    void aLargeLoopCountStandsInForPermanent() {
        PathTrajectoryDefinition path = new PathTrajectoryDefinition("trailing-loop", List.of(
            new PathSegment(0f, -40f, 1f),
            new PathSegment(-20f, 0f, 1f)),
            1, 10_000);

        // Still evaluable, still deterministic, still finite — just a very large finite bound.
        assertEquals(-20f, path.horizontalVelocityAt(500f));
    }

    @Test
    @DisplayName("rule 3: a path whose last segment holds still is refused at construction, not at runtime")
    void everyPathMustLeaveThePlayfield_pathThatEndsAtRestIsUnconstructible() {
        assertThrows(IllegalArgumentException.class, () -> new PathTrajectoryDefinition("hold-forever", List.of(
            new PathSegment(0f, -40f, 2f),
            new PathSegment(0f, 0f, 999_999f))));
    }

    @Test
    @DisplayName("rule 3: a loop range that ends at rest is refused too, even though it repeats")
    void everyPathMustLeaveThePlayfield_loopEndingAtRestIsUnconstructible() {
        assertThrows(IllegalArgumentException.class, () -> new PathTrajectoryDefinition("hold-in-loop", List.of(
            new PathSegment(0f, -40f, 1f),
            new PathSegment(-20f, 0f, 1f),
            new PathSegment(0f, 0f, 1f)),
            1, 5));
    }

    @Test
    @DisplayName("an empty segment list is refused")
    void emptySegmentListIsRefused() {
        assertThrows(IllegalArgumentException.class, () -> new PathTrajectoryDefinition("empty", List.of()));
    }

    @Test
    @DisplayName("a blank id is refused")
    void blankIdIsRefused() {
        assertThrows(IllegalArgumentException.class,
            () -> new PathTrajectoryDefinition("", List.of(new PathSegment(0f, -1f, 1f))));
    }

    @Test
    @DisplayName("a loopStart outside the segment range is refused")
    void loopStartOutOfRangeIsRefused() {
        List<PathSegment> segments = List.of(new PathSegment(0f, -1f, 1f));
        assertThrows(IllegalArgumentException.class,
            () -> new PathTrajectoryDefinition("bad-loop-start", segments, -1, 1));
        assertThrows(IllegalArgumentException.class,
            () -> new PathTrajectoryDefinition("bad-loop-start", segments, 2, 1));
    }

    @Test
    @DisplayName("a loopCount below one is refused")
    void loopCountBelowOneIsRefused() {
        List<PathSegment> segments = List.of(new PathSegment(0f, -1f, 1f));
        assertThrows(IllegalArgumentException.class,
            () -> new PathTrajectoryDefinition("bad-loop-count", segments, 0, 0));
    }

    @Test
    @DisplayName("a segment with a non-positive duration is refused")
    void nonPositiveDurationIsRefused() {
        assertThrows(IllegalArgumentException.class, () -> new PathSegment(0f, -1f, 0f));
        assertThrows(IllegalArgumentException.class, () -> new PathSegment(0f, -1f, -1f));
    }

    @Test
    @DisplayName("a mirrored path costs no second hand-written definition: negate vx per segment")
    void mirroringIsComposedFromTheSamePublicConstructor() {
        PathTrajectoryDefinition veerLeft = new PathTrajectoryDefinition("veer-left-path", List.of(
            new PathSegment(-20f, -40f, 2f),
            new PathSegment(-30f, -10f, 2f)));

        // The mechanism phase 11i settles on: read the original's segments through their public
        // accessors, negate vx, keep vy untouched, build a new instance of the same record type. No
        // core API is needed for this — the loader (task 2) does exactly this at content-load time.
        List<PathSegment> mirroredSegments = veerLeft.segments().stream()
            .map(segment -> new PathSegment(-segment.vx(), segment.vy(), segment.duration()))
            .toList();
        PathTrajectoryDefinition veerRight = new PathTrajectoryDefinition("veer-right-path", mirroredSegments);

        assertEquals(-veerLeft.vx(), veerRight.vx());
        assertEquals(veerLeft.vy(), veerRight.vy());
        assertEquals(-veerLeft.horizontalVelocityAt(1.5f), veerRight.horizontalVelocityAt(1.5f));
        assertEquals(veerLeft.verticalVelocityAt(1.5f), veerRight.verticalVelocityAt(1.5f));
    }
}
