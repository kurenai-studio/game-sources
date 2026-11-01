package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** One run's record and its one-line text form. */
class RunRecordTest {

    private static final Instant ENDED = Instant.parse("2026-07-06T10:15:30Z");

    private static RunRecord sample() {
        return new RunRecord(42L, "standard", Status.WON, 23, ENDED, 310,
                18, 27, 15, 5, 2, 3, 4);
    }

    /** A record written to a line parses back equal. */
    @Test
    void encodeParseRoundTrips() {
        RunRecord original = sample();
        assertEquals(Optional.of(original), RunRecord.parse(original.toLine()));
    }

    /** A record without a seed writes no seed key and parses back without one. */
    @Test
    void nullSeedRoundTripsAsAbsentKey() {
        RunRecord seedless = new RunRecord(null, "standard", Status.LOST, -24, ENDED, 100,
                3, 30, 0, 1, 0, 0, 2);
        String line = seedless.toLine();
        assertTrue(!line.contains("seed="), "seed key must be omitted");
        RunRecord parsed = RunRecord.parse(line).orElseThrow();
        assertNull(parsed.seed());
        assertEquals(seedless, parsed);
    }

    /** Unknown keys on a line are ignored. */
    @Test
    void unknownKeysAreIgnored() {
        String line = sample().toLine() + "\tfuturestat=99\tnote=hello";
        assertEquals(Optional.of(sample()), RunRecord.parse(line));
    }

    /** A line with only the essential keys parses, with every counter at zero and no seed. */
    @Test
    void missingCountersDefaultToZero() {
        String minimal = "v=1\truleset=standard\toutcome=WON\tscore=20\tended=" + ENDED;
        RunRecord parsed = RunRecord.parse(minimal).orElseThrow();
        assertEquals(0, parsed.monstersDefeated());
        assertEquals(0, parsed.damageTaken());
        assertEquals(0, parsed.seconds());
        assertNull(parsed.seed());
        assertEquals(20, parsed.score());
    }

    /** A line missing the version, outcome, score or end time parses to nothing. */
    @Test
    void linesMissingEssentialsAreRejected() {
        String base = sample().toLine();
        assertEquals(Optional.empty(), RunRecord.parse(base.replace("\toutcome=WON", "")));
        assertEquals(Optional.empty(), RunRecord.parse(base.replace("\tscore=23", "")));
        assertEquals(Optional.empty(), RunRecord.parse(base.replace("\tended=" + ENDED, "")));
        assertEquals(Optional.empty(), RunRecord.parse(base.replace("v=1\t", "")));
    }

    /** An unknown version, an unfinished outcome, an empty line or garbage parses to nothing. */
    @Test
    void unknownVersionsAndGarbageAreRejected() {
        assertEquals(Optional.empty(), RunRecord.parse(sample().toLine().replace("v=1", "v=2")));
        assertEquals(Optional.empty(), RunRecord.parse("### not a record ###"));
        assertEquals(Optional.empty(), RunRecord.parse(""));
        assertEquals(Optional.empty(), RunRecord.parse(sample().toLine().replace("outcome=WON", "outcome=IN_PROGRESS")));
    }

    /**
     * A record cannot be built for an unfinished run, a mode id containing
     * whitespace, or a missing end time.
     */
    @Test
    void constructorRejectsInvalidRecords() {
        assertThrows(IllegalArgumentException.class, () ->
                new RunRecord(1L, "standard", Status.IN_PROGRESS, 0, ENDED, 0, 0, 0, 0, 0, 0, 0, 0));
        assertThrows(IllegalArgumentException.class, () ->
                new RunRecord(1L, "bad id", Status.WON, 0, ENDED, 0, 0, 0, 0, 0, 0, 0, 0));
        assertThrows(IllegalArgumentException.class, () ->
                new RunRecord(1L, "standard", Status.WON, 0, null, 0, 0, 0, 0, 0, 0, 0, 0));
    }
}
