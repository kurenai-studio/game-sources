package gatorhunt;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AlligatorSpawnerTest {

    @Test
    void spawnsNothingBeforeAnyRowsIntervalHasPassed() {
        AlligatorSpawner spawner = new AlligatorSpawner(1920, 1080, 0L, new Random(42));

        // even with jitter, no row's interval can be this short
        List<Alligator> spawned = spawner.spawnDue(1L, 0, new Random(1), null, 140, 80);

        assertTrue(spawned.isEmpty());
    }

    @Test
    void everyRowHasSpawnedAtLeastOnceAfterAGenerousWait() {
        AlligatorSpawner spawner = new AlligatorSpawner(1920, 1080, 0L, new Random(42));

        // the slowest row's base interval is ~3.5s (speed ratio 2.5,
        // dampened by DENSITY_BIAS_EXPONENT); well past its worst-case
        // +20% jitter (~4.2s) guarantees every row has fired at least once
        long comfortablyPastSlowestRow = GameStats.NANOSECONDS_PER_SECOND * 8;
        List<Alligator> spawned = spawner.spawnDue(comfortablyPastSlowestRow, 0, new Random(1), null, 140, 80);

        assertTrue(spawned.size() == 4);
    }

    @Test
    void fastestRowIsNotDueBeforeItsInterval() {
        AlligatorSpawner spawner = new AlligatorSpawner(1920, 1080, 0L, new Random(42));

        // the fastest row's base interval is 2s; its worst-case -20%
        // jitter is still 1.6s, so nothing should be due by 1s
        List<Alligator> spawned = spawner.spawnDue(GameStats.NANOSECONDS_PER_SECOND, 0, new Random(1), null, 140, 80);

        assertTrue(spawned.isEmpty());
    }

    @Test
    void fasterRowsSpawnMoreOftenThanSlowerOnesOverTime() {
        AlligatorSpawner spawner = new AlligatorSpawner(1920, 1080, 0L, new Random(7));
        Random random = new Random(99);

        int fastestRowY = (int) (1080 * 0.82); // speed -10, base interval 2s
        int slowestRowY = (int) (1080 * 0.55); // speed -4, base interval ~3.5s
        int fastestCount = 0;
        int slowestCount = 0;

        long step = GameStats.NANOSECONDS_PER_SECOND / 10;
        long twoSimulatedMinutes = GameStats.NANOSECONDS_PER_SECOND * 120;
        for (long now = 0; now <= twoSimulatedMinutes; now += step) {
            for (Alligator alligator : spawner.spawnDue(now, 0, random, null, 140, 80)) {
                if (alligator.y == fastestRowY) {
                    fastestCount++;
                } else if (alligator.y == slowestRowY) {
                    slowestCount++;
                }
            }
        }

        // roughly 60 vs 46 spawns expected -- a wide enough margin that
        // +/-20% jitter on individual intervals can't flip the comparison
        assertTrue(fastestCount > slowestCount);
    }

    @Test
    void spawnsAlligatorsStartingOffTheRightEdgeOfTheScreen() {
        AlligatorSpawner spawner = new AlligatorSpawner(1920, 1080, 0L, new Random(42));

        List<Alligator> spawned = spawner.spawnDue(GameStats.NANOSECONDS_PER_SECOND * 5, 0, new Random(1), null, 140, 80);

        assertFalse(spawned.isEmpty());
        assertTrue(spawned.stream().allMatch(a -> a.x >= 1920));
    }

    @Test
    void spawnedAlligatorHasTheGivenSize() {
        AlligatorSpawner spawner = new AlligatorSpawner(1920, 1080, 0L, new Random(42));

        List<Alligator> spawned = spawner.spawnDue(GameStats.NANOSECONDS_PER_SECOND * 5, 0, new Random(1), null, 224, 128);

        assertFalse(spawned.isEmpty());
        assertTrue(spawned.stream().allMatch(a -> a.width == 224 && a.height == 128));
    }

    @Test
    void higherLevelsSpawnMoreOftenThanLevelZeroOverTime() {
        AlligatorSpawner levelZeroSpawner = new AlligatorSpawner(1920, 1080, 0L, new Random(7));
        AlligatorSpawner levelFiveSpawner = new AlligatorSpawner(1920, 1080, 0L, new Random(7));
        Random random = new Random(99);

        int levelZeroCount = 0;
        int levelFiveCount = 0;

        long step = GameStats.NANOSECONDS_PER_SECOND / 10;
        long twoSimulatedMinutes = GameStats.NANOSECONDS_PER_SECOND * 120;
        for (long now = 0; now <= twoSimulatedMinutes; now += step) {
            levelZeroCount += levelZeroSpawner.spawnDue(now, 0, random, null, 140, 80).size();
            levelFiveCount += levelFiveSpawner.spawnDue(now, 5, random, null, 140, 80).size();
        }

        // level 5 shrinks every row's interval to 1 / (1 + 0.1*5) = 1/1.5 of its
        // level-0 value, a wide enough margin that jitter can't flip the comparison
        assertTrue(levelFiveCount > levelZeroCount);
    }
}
