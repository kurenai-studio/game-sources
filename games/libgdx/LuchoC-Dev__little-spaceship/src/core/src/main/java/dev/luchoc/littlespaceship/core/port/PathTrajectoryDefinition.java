package dev.luchoc.littlespaceship.core.port;

import java.util.List;

/**
 * The {@code path} shape phase 11i adds: an ordered list of bounded {@link PathSegment}s, with a
 * trailing range of them repeated a bounded number of times. {@code
 * docs/plan/11i-path-vocabulary/plan.md} draws the vocabulary from eleven sketches — come down and
 * turn out sideways, enter horizontally then drop, a long diagonal, a curve into an exit, a wait of N
 * seconds mid-path, a trailing loop — and this is all three of "segments, waits and bounded repeats"
 * built as one shape: a wait is a segment (see {@link PathSegment}), and a repeat is a range of the
 * same list replayed.
 *
 * <p><strong>Still a pure function of elapsed time, with no new per-entity state.</strong>
 * {@code shape-catalogue.md} refused waypoints and segment lists outright: "each costs per-entity
 * path state well beyond the elapsed-time clock". That refusal is <em>dissolved</em>, not overridden,
 * by phase 11i's own bounding decision: with every segment's duration known up front and every loop
 * bounded to a fixed count, which segment is active at a given {@code elapsedSeconds} is found by
 * walking the list and accumulating durations — arithmetic on this definition's own fixed parameters,
 * exactly like {@link ArcTrajectoryDefinition}'s closed form, and {@link
 * dev.luchoc.littlespaceship.core.domain.component.Trajectory} still needs only {@code trajectoryId}
 * and {@code elapsed}. No waypoint index, no "which repeat am I on" counter, nothing cached on the
 * entity.
 *
 * <p><strong>Rule 3 — "every shape leaves the playfield unattended, in finite time" — is answered by
 * making the one shape that could violate it unconstructible.</strong> {@code enterAndHold} was
 * refused for exactly this: an entity at rest inside the playfield is never picked up by {@code
 * LifetimeSystem}'s off-screen check, so a {@code cleared} wave behind it can never end. A path built
 * from this record could reproduce that hazard by ending on a segment with zero velocity — the path
 * finishes its authored duration and then, per this class's own extrapolation past the end (see
 * {@link #verticalVelocityAt(float)}), holds that segment's velocity forever. The constructor refuses
 * exactly that case: <strong>the last segment in the list — which is also the last segment of the
 * repeated range, since the range always ends at the list's end — must have a nonzero velocity.</strong>
 * A path that violates this fails loudly at construction time, i.e. at content load, never silently
 * at runtime, and {@code PathTrajectoryDefinitionTest} carries the rule by name.
 *
 * <p>This is a necessary condition, not a geometric proof that every authored path actually crosses
 * the playfield's edge — that still depends on where the path starts (a wave's {@code atX}) and how
 * far its segments carry it, exactly as {@code shape-catalogue.md} already checks by hand for {@code
 * arc}'s entries. What this class refuses is the one case that is wrong regardless of placement: a
 * path that comes to rest and stays there is refused unconditionally, everywhere.
 *
 * <p><strong>An "indefinite" wait or a "permanent" loop, per the plan's own words, is simply a large
 * number</strong>: a {@link PathSegment} with a very long {@code duration}, or a loop {@code count} in
 * the thousands. To the player a unit that lingers fifteen seconds and one that lingers "forever" are
 * indistinguishable — they killed it or dodged it long before either elapses — so no separate
 * "unbounded" case is needed or offered.
 *
 * @param id the content id
 * @param segments the ordered list of legs this path is made of, copied defensively and never empty
 * @param loopStart index, into {@code segments}, of the first segment in the range that repeats;
 *     {@code segments.size()} means "no loop" — the list is simply played once, start to end
 * @param loopCount how many times the {@code [loopStart, segments.size())} range plays in total,
 *     including its first pass; must be at least 1. Ignored when {@code loopStart == segments.size()}
 */
public record PathTrajectoryDefinition(String id, List<PathSegment> segments, int loopStart, int loopCount)
    implements TrajectoryDefinition {

    /**
     * Rejects a trajectory that names nothing, an empty segment list, an out-of-range loop start, a
     * loop count below one, and — the answer to rule 3 — a path whose last segment cannot carry an
     * entity off screen because it holds still.
     */
    public PathTrajectoryDefinition {
        if (id == null || id.isEmpty()) {
            throw new IllegalArgumentException("a trajectory needs an id");
        }
        if (segments == null || segments.isEmpty()) {
            throw new IllegalArgumentException("a path trajectory needs at least one segment");
        }
        segments = List.copyOf(segments);
        if (loopStart < 0 || loopStart > segments.size()) {
            throw new IllegalArgumentException(
                "a path's loopStart must be within [0, segment count], was " + loopStart
                    + " for " + segments.size() + " segments");
        }
        if (loopCount < 1) {
            throw new IllegalArgumentException("a path's loopCount must be at least 1, was " + loopCount);
        }
        PathSegment last = segments.get(segments.size() - 1);
        if (last.vx() == 0f && last.vy() == 0f) {
            throw new IllegalArgumentException(
                "a path's last segment must have nonzero velocity — one that ends at rest would "
                    + "never leave the playfield, exactly the enterAndHold hazard the shape catalogue "
                    + "refused");
        }
    }

    /**
     * Convenience constructor for a path with no repeated range: the segments play once, start to
     * end, in order.
     *
     * @param id the content id
     * @param segments the ordered list of legs this path is made of
     */
    public PathTrajectoryDefinition(String id, List<PathSegment> segments) {
        this(id, segments, segments == null ? 0 : segments.size(), 1);
    }

    @Override
    public float vx() {
        return segmentAt(0f).vx();
    }

    @Override
    public float vy() {
        return segmentAt(0f).vy();
    }

    @Override
    public float horizontalVelocityAt(float elapsedSeconds) {
        return segmentAt(elapsedSeconds).vx();
    }

    @Override
    public float verticalVelocityAt(float elapsedSeconds) {
        return segmentAt(elapsedSeconds).vy();
    }

    /**
     * The segment active at a given elapsed time — the whole evaluation, since both velocity
     * components come from the same active leg. Walks {@link #segments} accumulating durations, no
     * allocation, no state beyond this call's own locals.
     *
     * <p>Once {@code elapsedSeconds} passes the path's total authored duration (prefix plus every
     * repeat of the loop range), the last segment's velocity is held indefinitely — the
     * extrapolation the constructor's rule-3 check relies on. That segment always carries nonzero
     * velocity, so an entity that overruns its path keeps moving in the direction its last leg set,
     * until {@code LifetimeSystem} removes it off screen.
     */
    private PathSegment segmentAt(float elapsedSeconds) {
        float prefixDuration = sumDurations(0, loopStart);
        if (elapsedSeconds < prefixDuration) {
            return segmentInRange(0, loopStart, elapsedSeconds);
        }
        float loopDuration = sumDurations(loopStart, segments.size());
        if (loopDuration <= 0f) {
            // loopStart == segments.size(): no loop range at all.
            return segments.get(segments.size() - 1);
        }
        float remaining = elapsedSeconds - prefixDuration;
        float totalLoopDuration = loopDuration * loopCount;
        if (remaining >= totalLoopDuration) {
            return segments.get(segments.size() - 1);
        }
        float localInLoop = remaining % loopDuration;
        return segmentInRange(loopStart, segments.size(), localInLoop);
    }

    private PathSegment segmentInRange(int fromInclusive, int toExclusive, float localTime) {
        float accumulated = 0f;
        for (int i = fromInclusive; i < toExclusive; i++) {
            PathSegment segment = segments.get(i);
            accumulated += segment.duration();
            if (localTime < accumulated) {
                return segment;
            }
        }
        return segments.get(toExclusive - 1);
    }

    private float sumDurations(int fromInclusive, int toExclusive) {
        float sum = 0f;
        for (int i = fromInclusive; i < toExclusive; i++) {
            sum += segments.get(i).duration();
        }
        return sum;
    }
}
