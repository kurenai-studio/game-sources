package dev.luchoc.littlespaceship.core.port;

/**
 * One leg of a {@link PathTrajectoryDefinition} — a fixed velocity held for a fixed duration.
 *
 * <p>A "wait", in the vocabulary {@code docs/plan/11i-path-vocabulary/plan.md} draws from the project
 * owner's sketches, is not a separate case: it is a segment with {@code vx = 0, vy = 0}, and an
 * "indefinite" wait is simply one with a very large {@code duration}. Both are content decisions, not
 * a distinct kind {@code core} needs to know about — the loader that reads {@code
 * assets/data/trajectories.json} (phase 11i task 2) is free to spell a wait however is most readable
 * in JSON and construct this record either way.
 *
 * @param vx horizontal velocity held for this segment's duration, in logical units per second
 * @param vy vertical velocity held for this segment's duration, in logical units per second,
 *     positive upwards like {@code Motion}
 * @param duration how long this segment lasts, in seconds; must be strictly positive so a path
 *     always makes finite progress through its segment list — a zero-duration leg would never be
 *     reached at all through elapsed-time evaluation and is refused instead of silently skipped
 */
public record PathSegment(float vx, float vy, float duration) {

    /**
     * Rejects a segment that cannot be evaluated: a non-finite velocity or a duration that is not
     * strictly positive.
     */
    public PathSegment {
        requireFinite(vx, "vx");
        requireFinite(vy, "vy");
        requireFinite(duration, "duration");
        if (duration <= 0f) {
            throw new IllegalArgumentException(
                "a path segment's duration must be strictly positive, was " + duration);
        }
    }

    private static void requireFinite(float value, String field) {
        if (Float.isNaN(value) || Float.isInfinite(value)) {
            throw new IllegalArgumentException(
                "a path segment's " + field + " must be a finite number, was " + value);
        }
    }
}
