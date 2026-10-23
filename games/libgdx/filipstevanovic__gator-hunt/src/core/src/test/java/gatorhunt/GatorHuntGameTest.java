package gatorhunt;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GatorHuntGameTest {

    private static final long SECOND = GameStats.NANOSECONDS_PER_SECOND;

    @Test
    void formatsZeroAsDoubleZero() {
        assertEquals("00:00", GatorHuntGame.formatElapsedTime(0L));
    }

    @Test
    void formatsSecondsUnderAMinute() {
        assertEquals("00:09", GatorHuntGame.formatElapsedTime(SECOND * 9));
        assertEquals("00:59", GatorHuntGame.formatElapsedTime(SECOND * 59));
    }

    @Test
    void rollsOverIntoMinutes() {
        assertEquals("01:00", GatorHuntGame.formatElapsedTime(SECOND * 60));
        assertEquals("01:05", GatorHuntGame.formatElapsedTime(SECOND * 65));
        assertEquals("05:00", GatorHuntGame.formatElapsedTime(SECOND * 300));
    }

    @Test
    void padsSingleDigitsWithLeadingZeros() {
        assertEquals("02:03", GatorHuntGame.formatElapsedTime(SECOND * 123));
    }
}
