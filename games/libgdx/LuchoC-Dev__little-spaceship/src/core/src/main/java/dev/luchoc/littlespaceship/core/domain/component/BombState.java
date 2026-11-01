package dev.luchoc.littlespaceship.core.domain.component;

/**
 * Whether the bomb control was held on the previous tick, so {@code BombSystem} can detect a
 * tick-level rising edge instead of spending a charge on every tick that reports it held.
 *
 * <p>{@code InputFrame.bomb()}'s own javadoc reads as an edge — "whether the bomb was requested
 * this tick" — but {@code GameLoop.advance} feeds the same {@code InputFrame} to every tick of one
 * rendered frame, and an adapter's "just pressed" edge is per render frame, not per tick. At a low
 * frame rate, or after the {@code MAX_FRAME_TIME} clamp lets a stall catch up, one press can reach
 * several ticks, and without this component {@code BombSystem} would spend one charge per tick
 * instead of one per press. Nothing else in the MVP needs this: {@code fire} is deliberately
 * level-shaped (sustained fire), and {@code slow} is a held modifier, so {@code bomb} is the first
 * — and, for now, the only — edge-shaped input the simulation consumes.
 */
public final class BombState {

    /** True when the bomb control was held on the previous tick. */
    public boolean heldLastTick;

    /**
     * Creates a bomb state with nothing held yet.
     */
    public BombState() {
        this(false);
    }

    /**
     * @param heldLastTick whether the bomb control was held on the previous tick
     */
    public BombState(boolean heldLastTick) {
        this.heldLastTick = heldLastTick;
    }
}
