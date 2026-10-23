package gatorhunt;

/**
 * Tracks how much faster alligators should move as a session goes on.
 *
 * Every full minute of play adds another 20% on top of each alligator's
 * base speed, stacking up to 5 minutes in (2x base speed), after which it
 * holds steady — the game keeps ramping up early, but doesn't spiral past
 * playable.
 */
public class DifficultyRamp {

    private static final long LEVEL_DURATION_NS = GameStats.NANOSECONDS_PER_SECOND * 60;
    private static final int MAX_LEVEL = 5;
    private static final float SPEED_INCREASE_PER_LEVEL = 0.2f;

    private final long startTime;

    public DifficultyRamp(long startTime) {
        this.startTime = startTime;
    }

    public int level(long now) {
        long elapsedLevels = (now - startTime) / LEVEL_DURATION_NS;
        return (int) Math.min(MAX_LEVEL, Math.max(0, elapsedLevels));
    }

    public float speedMultiplier(long now) {
        return 1f + SPEED_INCREASE_PER_LEVEL * level(now);
    }
}
