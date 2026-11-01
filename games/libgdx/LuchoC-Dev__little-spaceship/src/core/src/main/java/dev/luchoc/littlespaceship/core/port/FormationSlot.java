package dev.luchoc.littlespaceship.core.port;

/**
 * One position inside a {@link FormationDefinition}, relative to the wave's spawn anchor.
 *
 * <p>{@link #delaySeconds} is issue #330's addition: a slot that follows the one ahead of it,
 * delayed in time rather than displaced in space. Position and delay are deliberately separate
 * levers — a single-file column is {@code offsetX 0}, {@code offsetY 0} and a nonzero delay, while
 * every formation that existed before this issue keeps its offsets and a delay of zero. See {@link
 * dev.luchoc.littlespaceship.core.domain.component.Trajectory} and {@code MotionSystem} for what a
 * delayed slot's entity does before {@code delaySeconds} elapses.
 *
 * @param offsetX horizontal offset from the anchor, in logical units, positive to the right
 * @param offsetY vertical offset from the anchor, in logical units, positive upwards like
 *     {@code Transform}
 * @param delaySeconds how long this slot's entity holds still, from the moment its wave spawns it,
 *     before it starts following its trajectory; {@code 0} for a slot with no delay, which is every
 *     formation this issue found in the repository
 */
public record FormationSlot(float offsetX, float offsetY, float delaySeconds) {

    /**
     * Rejects a delay that could never be honoured — negative time held still has no meaning, and a
     * {@code NaN} or infinite value would silently break the elapsed-time arithmetic {@code
     * MotionSystem} does with it.
     */
    public FormationSlot {
        if (Float.isNaN(delaySeconds) || Float.isInfinite(delaySeconds) || delaySeconds < 0f) {
            throw new IllegalArgumentException(
                "a formation slot's delay must be a finite, non-negative number, was " + delaySeconds);
        }
    }

    /**
     * Convenience constructor for the common case, and the one every formation used before issue
     * #330: no delay, the leader of its own single-slot file.
     *
     * @param offsetX horizontal offset from the anchor
     * @param offsetY vertical offset from the anchor
     */
    public FormationSlot(float offsetX, float offsetY) {
        this(offsetX, offsetY, 0f);
    }
}
