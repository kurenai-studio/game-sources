package gatorhunt;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Mutable state for one game session: the alligators currently on
 * screen, the score, and shot timing. Pure logic, no rendering — kept
 * independent of any platform so it can be unit tested directly.
 */
public class GameStats {

    public static final long NANOSECONDS_PER_SECOND = 1_000_000_000L;

    /** A shot can only be fired once this much time has passed since the last one. */
    public static final long SHOT_COOLDOWN_NS = NANOSECONDS_PER_SECOND / 3;

    private final List<Alligator> alligators = new ArrayList<>();
    private final Random random = new Random();

    private int escapedCount;
    private int killedCount;
    private int score;
    private int shotsFired;
    private long lastShotTime;

    public Random getRandom() {
        return random;
    }

    public List<Alligator> getAlligators() {
        return alligators;
    }

    public int getEscapedCount() {
        return escapedCount;
    }

    public void incrementEscapedCount() {
        escapedCount++;
    }

    public int getKilledCount() {
        return killedCount;
    }

    public void incrementKilledCount() {
        killedCount++;
    }

    public int getScore() {
        return score;
    }

    public void addScore(int points) {
        score += points;
    }

    public int getShotsFired() {
        return shotsFired;
    }

    public void incrementShotsFired() {
        shotsFired++;
    }

    public long getLastShotTime() {
        return lastShotTime;
    }

    public void setLastShotTime(long lastShotTime) {
        this.lastShotTime = lastShotTime;
    }

    public boolean canFireShot(long now) {
        return now - lastShotTime >= SHOT_COOLDOWN_NS;
    }
}
