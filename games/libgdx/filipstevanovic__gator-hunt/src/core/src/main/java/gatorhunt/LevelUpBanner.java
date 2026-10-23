package gatorhunt;

/**
 * Tracks whether a brief "LEVEL X" announcement should currently be shown,
 * by watching {@link DifficultyRamp}'s level number for changes.
 *
 * Starts with no level seen yet, so the very first call to update() --
 * level 0, right as a session begins -- counts as a change too and shows
 * the banner, the same as every later level-up.
 */
public class LevelUpBanner {

    private static final long DISPLAY_DURATION_NS = GameStats.NANOSECONDS_PER_SECOND * 2;
    private static final int NO_LEVEL_SEEN_YET = -1;

    private int lastLevel = NO_LEVEL_SEEN_YET;
    private long visibleUntil = Long.MIN_VALUE;

    /** Call once per frame with the current difficulty level; starts (or restarts) the display timer on a change. */
    public void update(int currentLevel, long now) {
        if (currentLevel != lastLevel) {
            lastLevel = currentLevel;
            visibleUntil = now + DISPLAY_DURATION_NS;
        }
    }

    public boolean isVisible(long now) {
        return now < visibleUntil;
    }

    /** The level the banner is (or was last) announcing. */
    public int level() {
        return lastLevel;
    }
}
