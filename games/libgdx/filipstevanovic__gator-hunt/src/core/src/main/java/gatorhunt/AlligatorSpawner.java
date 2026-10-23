package gatorhunt;

import com.badlogic.gdx.graphics.Texture;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Spawns alligators into four rows that move at different speeds.
 *
 * Each row gets its own spawn interval, inversely related to its speed
 * by DENSITY_BIAS_EXPONENT below. A single shared interval (as the
 * original AWT version used) makes the slow rows pile up badly: a fast
 * row clears itself almost as quickly as new alligators arrive, but a
 * slow one doesn't, so it keeps accumulating. Fully equalizing density
 * (every row ends up with the same count) fixes that but reads as too
 * uniform; the current exponent leaves slower rows moderately fuller
 * than faster ones without the original pile-up.
 *
 * Kept as per-session instance state (rather than the static globals
 * the original AWT version used) so a restarted game starts clean.
 */
public class AlligatorSpawner {

    // The original AWT version cycled through all 4 rows on one shared
    // 0.5s timer, so any GIVEN row actually only got a new alligator every
    // 4 * 0.5s = 2s -- not every 0.5s, which was a mistake the first time
    // this was tuned (it used the 0.5s round-robin *check* interval as if
    // it were a single row's own interval, making every row spawn 4x more
    // often than before instead of just rebalancing the slow one).
    // The fastest row keeps that real, original 2s pacing; every other
    // row's interval scales up from there (see DENSITY_BIAS_EXPONENT).
    private static final long FASTEST_ROW_INTERVAL_NS = GameStats.NANOSECONDS_PER_SECOND * 2;
    private static final int FASTEST_ROW_SPEED = 10;

    /**
     * How strongly a row's interval follows its speed ratio to the fastest
     * row: 1.0 = fully proportional (equal density in every row); 0.0 =
     * every row shares the fastest row's interval (the original bug, where
     * slow rows pile up badly). A middle value gives slower rows more
     * density than a "fair" split would, without the pile-up.
     *
     * 0.6 (equal standing count ~2.3 vs ~1.6 between slowest and fastest
     * row) turned out too subtle to actually notice during play -- small
     * absolute counts plus jitter's noise buried the difference. 0.3
     * widens that to ~3.0 vs ~1.6, which reads clearly without going back
     * to the original uncontrolled pile-up (~4.0, at exponent 0).
     */
    private static final double DENSITY_BIAS_EXPONENT = 0.3;

    /** Each row's actual interval is jittered by up to this fraction of its base value, so spawns don't land in a perfectly mechanical rhythm. */
    private static final double JITTER_FRACTION = 0.2;

    /** Extra spawn density added per difficulty level, layered on top of the per-row base interval below (see DifficultyRamp). */
    private static final double DENSITY_INCREASE_PER_LEVEL = 0.1;

    /** One row per entry: {startX, y, speed, points}. Speed is negative — alligators move leftward. */
    private final int[][] spawnRows;
    private final long[] baseIntervalNs;
    private final long[] nextIntervalNs;
    private final long[] lastSpawnTime;

    public AlligatorSpawner(int screenWidth, int screenHeight, long now, Random random) {
        // spaced further apart than a plain 1/N split of the screen, since
        // drawn alligators are scaled up noticeably from their sprite's
        // native size (see GatorHuntGame.ALLIGATOR_SCALE)
        // 2x the original AWT version's speeds, so there's less reaction time
        spawnRows = new int[][] {
            { screenWidth, (int) (screenHeight * 0.55), -4, 20 },
            { screenWidth, (int) (screenHeight * 0.64), -6, 30 },
            { screenWidth, (int) (screenHeight * 0.73), -8, 40 },
            { screenWidth, (int) (screenHeight * 0.82), -10, 50 },
        };

        baseIntervalNs = new long[spawnRows.length];
        nextIntervalNs = new long[spawnRows.length];
        lastSpawnTime = new long[spawnRows.length];
        for (int i = 0; i < spawnRows.length; i++) {
            int speed = Math.abs(spawnRows[i][2]);
            double speedRatio = (double) FASTEST_ROW_SPEED / speed;
            baseIntervalNs[i] = (long) (FASTEST_ROW_INTERVAL_NS * Math.pow(speedRatio, DENSITY_BIAS_EXPONENT));
            nextIntervalNs[i] = jittered(baseIntervalNs[i], 0, random);
            // starts each row's clock at construction time, rather than
            // System.nanoTime()'s arbitrary large epoch, so rows don't all
            // spawn simultaneously on the very first check
            lastSpawnTime[i] = now;
        }
    }

    /** Spawns into every row whose own interval has elapsed since its last spawn — usually none, sometimes one. */
    public List<Alligator> spawnDue(long now, int level, Random random, Texture image, int width, int height) {
        List<Alligator> spawned = new ArrayList<>(1);

        for (int i = 0; i < spawnRows.length; i++) {
            if (now - lastSpawnTime[i] >= nextIntervalNs[i]) {
                int[] row = spawnRows[i];
                int startX = row[0] + random.nextInt(200);
                spawned.add(new Alligator(startX, row[1], row[2], row[3], width, height, image));
                lastSpawnTime[i] = now;
                nextIntervalNs[i] = jittered(baseIntervalNs[i], level, random);
            }
        }

        return spawned;
    }

    /**
     * Randomizes an interval by up to +/- JITTER_FRACTION, keeping the long-run average equal to base,
     * then shrinks it by DENSITY_INCREASE_PER_LEVEL per difficulty level so higher levels spawn more often.
     */
    private long jittered(long base, int level, Random random) {
        double jitterFactor = 1.0 + (random.nextDouble() * 2 - 1) * JITTER_FRACTION;
        double densityMultiplier = 1.0 + DENSITY_INCREASE_PER_LEVEL * level;
        return (long) (base * jitterFactor / densityMultiplier);
    }
}
