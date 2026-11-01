package dev.luchoc.littlespaceship.core.application;

import dev.luchoc.littlespaceship.core.port.InputFrame;

/**
 * Turns the real, variable time of a frame into a whole number of fixed steps.
 *
 * <p>The simulation never sees a variable delta. A variable delta makes the result depend on the
 * frame rate of the machine that ran it, which destroys determinism and with it every replay. What
 * varies is how many ticks a frame produces, not how long a tick lasts.
 *
 * <p>The leftover time stays in the accumulator and is used by the next frame, so no time is lost
 * and none is invented. Frames longer than {@link #MAX_FRAME_TIME} are clamped: without that clamp,
 * a stall -- a breakpoint, a window drag, a browser tab in the background -- would produce a burst
 * of ticks that takes even longer to simulate, which makes the next frame worse. That is the spiral
 * of death, and the clamp is the whole defence against it.
 *
 * <p>There is no interpolation. In pixel art with positions snapped to whole pixels it adds little
 * and complicates a lot; if it is ever missed, it belongs to the presentation layer and not here.
 */
public final class GameLoop {

    /** Duration of one tick, in seconds. Sixty per second. This is what every system receives. */
    public static final float STEP = 1f / 60f;

    /** Longest frame the loop will honour, in seconds. Anything above it is time simply dropped. */
    public static final float MAX_FRAME_TIME = 0.25f;

    /**
     * The same step in double precision, used only to add and subtract time.
     *
     * <p>A float accumulator loses enough precision to turn one second into fifty-nine ticks at
     * some frame rates and sixty at others, which is exactly the dependency on frame rate this
     * class exists to remove. The value the simulation receives is still {@link #STEP}, so nothing
     * about determinism changes: what gains precision is the bookkeeping, not the game.
     */
    private static final double STEP_SECONDS = 1.0 / 60.0;

    private final TickHandler target;

    private double accumulator;
    private int totalTicks;

    /**
     * Creates a loop that advances the given target.
     *
     * @param target what gets ticked, never null
     */
    public GameLoop(TickHandler target) {
        if (target == null) {
            throw new IllegalArgumentException("a loop needs something to tick");
        }
        this.target = target;
    }

    /**
     * Consumes the time of one rendered frame and runs as many ticks as fit in it.
     *
     * <p>Every tick of the same frame receives the same input frame: the adapter samples the
     * devices once per frame. Whoever records a replay records what each tick received, not what
     * each frame sampled.
     *
     * @param frameTime seconds elapsed since the previous frame, never negative
     * @param input what the player asked for, immutable
     * @return how many ticks were run, possibly zero
     * @throws IllegalArgumentException if the frame time is negative or not finite
     */
    public int advance(float frameTime, InputFrame input) {
        if (frameTime < 0f || Float.isNaN(frameTime) || Float.isInfinite(frameTime)) {
            throw new IllegalArgumentException(
                "frame time must be finite and positive, was " + frameTime);
        }
        if (input == null) {
            throw new IllegalArgumentException("a tick needs an input frame");
        }

        accumulator += Math.min(frameTime, MAX_FRAME_TIME);

        int ticks = 0;
        while (accumulator >= STEP_SECONDS) {
            target.tick(STEP, input);
            accumulator -= STEP_SECONDS;
            ticks++;
        }
        totalTicks += ticks;
        return ticks;
    }

    /**
     * Returns how many ticks this loop has run since it was created or last reset.
     *
     * @return the total tick count
     */
    public int totalTicks() {
        return totalTicks;
    }

    /**
     * Returns the time left over, shorter than one step, waiting for the next frame.
     *
     * @return the pending seconds
     */
    public float pendingTime() {
        return (float) accumulator;
    }

    /**
     * Drops the leftover time and the tick count, for when a new run starts.
     */
    public void reset() {
        accumulator = 0.0;
        totalTicks = 0;
    }
}
