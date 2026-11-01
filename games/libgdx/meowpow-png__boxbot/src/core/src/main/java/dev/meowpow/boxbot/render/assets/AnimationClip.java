package dev.meowpow.boxbot.render.assets;

import dev.meowpow.boxbot.engine.time.AlphaTimer;
import dev.meowpow.boxbot.gdx.HotPath;

/**
 * A looping sequence of frames,
 * played back over a fixed duration.
 */
@HotPath
public final class AnimationClip {

    private final EntitySprite[] frames;
    private final AlphaTimer timer;

    /**
     * Creates a clip that loops through the given frames.
     *
     * @param frames the frames to play, in order
     * @param secondsPerFrame time each frame is shown, in seconds
     *
     * @throws IllegalArgumentException if {@code frames}
     * is empty or {@code secondsPerFrame} is not positive
     */
    public AnimationClip(EntitySprite[] frames, float secondsPerFrame) {
        if (frames.length == 0) {
            throw new IllegalArgumentException("frames must not be empty");
        }
        if (Float.isNaN(secondsPerFrame) || secondsPerFrame <= 0) {
            throw new IllegalArgumentException("secondsPerFrame must be > 0, got " + secondsPerFrame);
        }
        this.frames = frames;
        this.timer = new AlphaTimer(frames.length * secondsPerFrame);
    }

    /**
     * Restarts this clip from its first frame.
     */
    void restart() {
        timer.reset();
        timer.update(0f);
    }

    /**
     * Advances this clip by {@code delta} seconds,
     * looping back to the first frame once finished.
     *
     * @param delta elapsed time since the last call, in seconds
     */
    void advance(float delta) {
        if (timer.isFinished()) {
            timer.reset();
        }
        timer.update(delta);
    }

    /**
     * Returns the frame at this clip's current elapsed time.
     */
    EntitySprite frame() {
        int index = (int) (timer.alpha().value() * frames.length);
        return frames[Math.min(index, frames.length - 1)];
    }
}
