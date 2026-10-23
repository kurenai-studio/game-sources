package gatorhunt;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class DifficultyRampTest {

    private static final long MINUTE = GameStats.NANOSECONDS_PER_SECOND * 60;

    @Test
    void startsAtBaseSpeed() {
        DifficultyRamp ramp = new DifficultyRamp(0L);

        assertEquals(1.0f, ramp.speedMultiplier(0L));
        assertEquals(1.0f, ramp.speedMultiplier(MINUTE - 1));
    }

    @Test
    void addsTwentyPercentPerFullMinuteElapsed() {
        DifficultyRamp ramp = new DifficultyRamp(0L);

        assertEquals(1.2f, ramp.speedMultiplier(MINUTE));
        assertEquals(1.4f, ramp.speedMultiplier(MINUTE * 2));
        assertEquals(1.6f, ramp.speedMultiplier(MINUTE * 3));
        assertEquals(1.8f, ramp.speedMultiplier(MINUTE * 4));
    }

    @Test
    void capsAtDoubleSpeedFiveMinutesIn() {
        DifficultyRamp ramp = new DifficultyRamp(0L);

        assertEquals(2.0f, ramp.speedMultiplier(MINUTE * 5));
        assertEquals(2.0f, ramp.speedMultiplier(MINUTE * 5 + 1));
        assertEquals(2.0f, ramp.speedMultiplier(MINUTE * 60));
    }

    @Test
    void isRelativeToItsOwnStartTimeNotZero() {
        long sessionStart = 987_654_321L;
        DifficultyRamp ramp = new DifficultyRamp(sessionStart);

        assertEquals(1.0f, ramp.speedMultiplier(sessionStart));
        assertEquals(1.2f, ramp.speedMultiplier(sessionStart + MINUTE));
    }
}
