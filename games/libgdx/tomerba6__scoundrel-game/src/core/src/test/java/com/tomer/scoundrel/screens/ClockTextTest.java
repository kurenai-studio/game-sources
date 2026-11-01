package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** The one run-duration formatter, shared by the HUD timer, end screen, and ledger. */
class ClockTextTest {

    /** Under a minute reads as 0:SS. */
    @Test
    void underAMinuteReadsZeroMinutes() {
        assertEquals("0:00", ClockText.format(0));
        assertEquals("0:07", ClockText.format(7));
        assertEquals("0:42", ClockText.format(42));
    }

    /** Under an hour reads as M:SS, the seconds padded to two digits. */
    @Test
    void minutesAndSecondsAreColonSeparatedWithPaddedSeconds() {
        assertEquals("1:00", ClockText.format(60));
        assertEquals("12:07", ClockText.format(12 * 60 + 7));
        assertEquals("59:59", ClockText.format(59 * 60 + 59));
    }

    /** An hour or more reads as hours and whole minutes, dropping the seconds. */
    @Test
    void anHourOrMoreDropsToCoarseHoursAndMinutes() {
        assertEquals("1h 0m", ClockText.format(3600));
        assertEquals("1h 3m", ClockText.format(3600 + 3 * 60 + 30));
        assertEquals("2h 15m", ClockText.format(2 * 3600 + 15 * 60 + 59));
    }
}
