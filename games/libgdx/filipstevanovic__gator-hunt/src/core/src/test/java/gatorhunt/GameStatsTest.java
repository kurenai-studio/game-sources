package gatorhunt;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GameStatsTest {

    @Test
    void startsEmptyWithZeroedCounters() {
        GameStats stats = new GameStats();

        assertTrue(stats.getAlligators().isEmpty());
        assertEquals(0, stats.getEscapedCount());
        assertEquals(0, stats.getKilledCount());
        assertEquals(0, stats.getScore());
        assertEquals(0, stats.getShotsFired());
    }

    @Test
    void tracksEscapedAndKilledCountsIndependently() {
        GameStats stats = new GameStats();

        stats.incrementEscapedCount();
        stats.incrementEscapedCount();
        stats.incrementKilledCount();

        assertEquals(2, stats.getEscapedCount());
        assertEquals(1, stats.getKilledCount());
    }

    @Test
    void accumulatesScoreAcrossMultipleKills() {
        GameStats stats = new GameStats();

        stats.addScore(20);
        stats.addScore(30);

        assertEquals(50, stats.getScore());
    }

    @Test
    void enforcesTheShotCooldown() {
        GameStats stats = new GameStats();
        stats.setLastShotTime(1000L);

        assertFalse(stats.canFireShot(1000L + GameStats.SHOT_COOLDOWN_NS - 1));
        assertTrue(stats.canFireShot(1000L + GameStats.SHOT_COOLDOWN_NS));
    }
}
