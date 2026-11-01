package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameEvent;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.util.List;

import static com.tomer.scoundrel.runs.RunsTestData.monster;
import static com.tomer.scoundrel.runs.RunsTestData.potion;
import static com.tomer.scoundrel.runs.RunsTestData.result;
import static com.tomer.scoundrel.runs.RunsTestData.sequenceClock;
import static com.tomer.scoundrel.runs.RunsTestData.weapon;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Building a run's record from the events the engine reports. */
class RunRecorderTest {

    private static final Clock FIXED = Clock.fixed(Instant.parse("2026-07-06T10:00:00Z"), java.time.ZoneOffset.UTC);

    /** Every counter is tallied from the events observed, and the final outcome and score are kept. */
    @Test
    void talliesCountersFromEvents() {
        RunRecorder recorder = new RunRecorder(42L, "standard", FIXED);
        recorder.observe(result(
                new GameEvent.MonsterDefeated(monster("JC", 11), true, 6),
                new GameEvent.WeaponDegraded(weapon(5), 11),
                new GameEvent.RoomDealt(List.of())));
        recorder.observe(result(
                new GameEvent.MonsterDefeated(monster("2S", 2), false, 2),
                new GameEvent.PotionUsed(potion(7), 5),
                new GameEvent.PotionUsed(potion(3), 0),
                new GameEvent.PotionWasted(potion(2)),
                new GameEvent.WeaponEquipped(weapon(5)),
                new GameEvent.RoomAvoided(List.of())));
        recorder.observe(result(new GameEvent.GameLost(-24)));

        RunRecord record = recorder.toRecord();
        assertEquals(2, record.monstersDefeated());
        assertEquals(8, record.damageTaken());
        assertEquals(2, record.potionsDrunk());
        assertEquals(5, record.healthHealed());
        assertEquals(1, record.potionsWasted());
        assertEquals(1, record.weaponsEquipped());
        assertEquals(1, record.roomsAvoided());
        assertEquals(Status.LOST, record.outcome());
        assertEquals(-24, record.score());
    }

    /** A win finishes the run and is recorded with its score. */
    @Test
    void winIsCapturedWithItsScore() {
        RunRecorder recorder = new RunRecorder(7L, "standard", FIXED);
        recorder.observe(result(new GameEvent.GameWon(23)));
        assertTrue(recorder.isFinished());
        RunRecord record = recorder.toRecord();
        assertEquals(Status.WON, record.outcome());
        assertEquals(23, record.score());
    }

    /** Asking for the record before the run has ended throws IllegalStateException. */
    @Test
    void toRecordBeforeTheGameEndsThrows() {
        RunRecorder recorder = new RunRecorder(7L, "standard", FIXED);
        recorder.observe(result(new GameEvent.PotionUsed(potion(5), 5)));
        assertFalse(recorder.isFinished());
        assertThrows(IllegalStateException.class, recorder::toRecord);
    }

    /** The record's end time and duration come from the clock. */
    @Test
    void clockDrivesTimestampAndDuration() {
        Instant start = Instant.parse("2026-07-06T10:00:00Z");
        Instant end = Instant.parse("2026-07-06T10:05:10Z");
        RunRecorder recorder = new RunRecorder(1L, "standard", sequenceClock(start, end));
        recorder.observe(result(new GameEvent.GameWon(20)));
        RunRecord record = recorder.toRecord();
        assertEquals(end, record.endedAt());
        assertEquals(310, record.seconds());
    }

    /** Elapsed time reads zero before the clock moves. */
    @Test
    void elapsedSecondsIsZeroAtTheStart() {
        RunRecorder recorder = new RunRecorder(1L, "standard", FIXED);
        assertEquals(0, recorder.elapsedSeconds());
    }

    /** Elapsed time counts from the start at each reading of the clock. */
    @Test
    void elapsedSecondsTracksTheClockFromTheStart() {
        Instant start = Instant.parse("2026-07-06T10:00:00Z");
        Instant t1 = Instant.parse("2026-07-06T10:00:42Z");
        Instant t2 = Instant.parse("2026-07-06T10:03:07Z");
        RunRecorder recorder = new RunRecorder(1L, "standard", sequenceClock(start, t1, t2));
        assertEquals(42, recorder.elapsedSeconds());
        assertEquals(187, recorder.elapsedSeconds());
    }

    /** The seed and mode id reach the record unchanged, a missing seed included. */
    @Test
    void seedAndRulesetIdPassThrough() {
        RunRecorder withSeed = new RunRecorder(42L, "standard", FIXED);
        withSeed.observe(result(new GameEvent.GameWon(20)));
        assertEquals(42L, withSeed.toRecord().seed());
        assertEquals("standard", withSeed.toRecord().rulesetId());

        RunRecorder seedless = new RunRecorder(null, "standard", FIXED);
        seedless.observe(result(new GameEvent.GameLost(-5)));
        assertNull(seedless.toRecord().seed());
    }
}
