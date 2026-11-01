package dev.luchoc.littlespaceship.core.port;

/**
 * A movement shape, referenced by id from an archetype's {@code "motion"} component or from a
 * {@code SpawnEvent}'s override — a function from an entity's own elapsed time since spawn to a
 * velocity, per {@code docs/plan/11c-movement-shapes/shape-catalogue.md} and, for the path kind
 * below, {@code docs/plan/11i-path-vocabulary/plan.md}.
 *
 * <p>Sealed to the three kinds the catalogue and phase 11i decide, and refuses the rest, the same
 * reason {@link WaveEndCondition} is sealed: the system evaluating one (issue #164, extended by
 * #259) can switch on which it is without a fourth, unnamed case ever compiling.
 * {@link SimpleTrajectoryDefinition} is a fixed velocity; {@link ArcTrajectoryDefinition} is a fixed
 * velocity with constant vertical acceleration; {@link PathTrajectoryDefinition} is an ordered list
 * of bounded segments, with waits and a bounded repeat expressed as segments and a loop range —
 * phase 11i's addition, argued in full on {@link PathTrajectoryDefinition}'s own javadoc.
 *
 * <p>Horizontal velocity never varies with time in {@link SimpleTrajectoryDefinition} or
 * {@link ArcTrajectoryDefinition} — the catalogue names no case for horizontal acceleration in either
 * — so {@link #vx()} alone used to answer it. A path that turns needs the horizontal component to be
 * a function of elapsed time too, symmetric with {@link #verticalVelocityAt(float)}, which is what
 * {@link #horizontalVelocityAt(float)} adds. Its default body returns {@link #vx()} unconditionally,
 * which is exactly right for the two kinds that predate it and costs them no change at all —
 * only {@link PathTrajectoryDefinition} overrides it.
 *
 * <p><strong>Mirroring is not a fourth kind.</strong> Phase 11i asked for a mirrored shape to cost no
 * second hand-written definition, and the answer is composition at content-load time rather than a
 * new sealed permit: every implementation here is a public record whose fields are all readable
 * through their accessors, so a loader can build a mirrored copy of any of them — negate {@code vx}
 * (and, for a path, every segment's {@code vx}), keep every vertical field untouched, assign the
 * mirror its own id — using the same public constructor the original went through. Nothing in
 * {@code core} needs to know a definition is a mirror of another; the mirror is simply a second,
 * independently valid instance of the same record type.
 *
 * <p>Kept separate from {@link EnemyDefinition} precisely so it can be shared: the same id attached
 * to two different archetypes' {@code "motion"} spec is what makes "a tank on the super-fast's
 * trajectory" a one-line data change.
 */
public sealed interface TrajectoryDefinition
    permits SimpleTrajectoryDefinition, ArcTrajectoryDefinition, PathTrajectoryDefinition {

    /**
     * @return the content id
     */
    String id();

    /**
     * @return horizontal velocity at elapsed time zero, in logical units per second — constant for
     *     the whole life of an entity following {@link SimpleTrajectoryDefinition} or
     *     {@link ArcTrajectoryDefinition}, but only the value at zero for {@link
     *     PathTrajectoryDefinition} — equivalent to {@code horizontalVelocityAt(0f)}
     */
    float vx();

    /**
     * @return vertical velocity at elapsed time zero, in logical units per second, positive upwards
     *     like {@code Motion} — equivalent to {@code verticalVelocityAt(0f)}
     */
    float vy();

    /**
     * Evaluates this shape's horizontal velocity at a given point in an entity's life, symmetric with
     * {@link #verticalVelocityAt(float)}. A pure function of {@code elapsedSeconds} and this shape's
     * own parameters — reads nothing else, per the catalogue's first rule, and carries no randomness,
     * per its second.
     *
     * <p>Defaults to {@link #vx()} unconditionally: right for every kind before {@link
     * PathTrajectoryDefinition}, which is the only one that overrides it.
     *
     * @param elapsedSeconds seconds since the entity carrying this shape spawned, accumulated from
     *     the fixed step so a replay reproduces it exactly; never the system clock
     * @return horizontal velocity at that instant, in logical units per second
     */
    default float horizontalVelocityAt(float elapsedSeconds) {
        return vx();
    }

    /**
     * Evaluates this shape's vertical velocity at a given point in an entity's life. A pure function
     * of {@code elapsedSeconds} and this shape's own parameters — reads nothing else, per the
     * catalogue's first rule, and carries no randomness, per its second.
     *
     * @param elapsedSeconds seconds since the entity carrying this shape spawned, accumulated from
     *     the fixed step so a replay reproduces it exactly; never the system clock
     * @return vertical velocity at that instant, in logical units per second, positive upwards
     */
    float verticalVelocityAt(float elapsedSeconds);
}
