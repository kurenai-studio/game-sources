package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Which movement shape an entity follows, and how long it has followed it — accumulated from the
 * fixed step.
 *
 * <p>{@code docs/plan/11c-movement-shapes/shape-catalogue.md} settles what a movement shape is
 * allowed to read: "a function from the entity's own elapsed time to its velocity. Nothing else goes
 * in." {@link #elapsed} is that one input, paired with {@link #trajectoryId} so {@code MotionSystem}
 * knows which shape to evaluate it against. Neither kind the catalogue defines — {@code constant} or
 * {@code arc} — reads a position, so this component carries none: an origin field would be an
 * abstraction with no case, which is exactly what invariant 6 refuses.
 *
 * <p>The id is stored rather than the resolved {@code TrajectoryDefinition} itself, the same pattern
 * {@link Spawner#enemyId} already uses for a content reference on a component — a plain string that
 * {@code World.content()} resolves each time it is needed, rather than a cached object a content
 * reload could leave stale.
 *
 * <p>Attached to every entity {@code ComponentFactoryRegistry.attachMotion} gives a {@link Motion}
 * to, {@code constant} shapes included: {@code MotionSystem} re-evaluates {@link #trajectoryId}'s
 * vertical velocity every tick regardless of kind, and a {@code constant} shape's {@code
 * verticalVelocityAt} ignores elapsed time and returns the same value it always has, so the result is
 * identical to the one-time snapshot that shipped before this component was wired in. Issue #164
 * wires this evaluation into {@code MotionSystem.advanceTrajectories}; before that, this component
 * only accumulated {@link #elapsed} and nothing read {@link #trajectoryId}.
 *
 * <p>Issue #330 originally reused {@link #elapsed} for a delayed formation slot by starting it
 * negative and holding the entity still while {@code elapsed <= 0f}. <b>Issue #337 correction:</b>
 * that compared a value reached by a single multiplication ({@code delayTicks * step}, however it was
 * constructed) against a value reached by repeated addition ({@code elapsed += step}, once per tick)
 * — two float paths to the same target that do not generally agree bit-for-bit, so the crossing
 * landed one tick early for roughly a fifth of all tick counts, swept over 1..300. {@link
 * #delayTicks} replaces that: an integer countdown, decremented once per tick by {@code MotionSystem},
 * with no float comparison anywhere near the crossing. {@link #elapsed} now always starts at, and is
 * held at, {@code 0} for as long as {@link #delayTicks} is positive — it never goes negative — and
 * only begins accumulating once the countdown reaches zero, at which point its first increment lands
 * on exactly the same value an undelayed entity's own first increment would.
 */
public final class Trajectory {

    /** Content id of the {@link dev.luchoc.littlespaceship.core.port.TrajectoryDefinition} followed. */
    public String trajectoryId;

    /** Seconds elapsed since this entity started following its shape, accumulated from the fixed step. */
    public float elapsed;

    /**
     * Whole ticks left to hold this entity still before {@link #elapsed} starts accumulating —
     * issue #330's delayed formation slot, corrected by issue #337 to count ticks rather than compare
     * floats at the crossing. {@code 0} for every entity with no delay, which is every trajectory that
     * predates #330.
     */
    public int delayTicks;

    /**
     * @param trajectoryId content id of the movement shape this entity follows, never null or empty
     */
    public Trajectory(String trajectoryId) {
        if (trajectoryId == null || trajectoryId.isEmpty()) {
            throw new IllegalArgumentException("a trajectory needs a movement shape id");
        }
        this.trajectoryId = trajectoryId;
        this.elapsed = 0f;
        this.delayTicks = 0;
    }
}
