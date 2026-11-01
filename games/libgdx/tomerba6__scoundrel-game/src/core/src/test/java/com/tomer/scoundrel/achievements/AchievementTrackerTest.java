package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameEvent;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.achievements.AchievementsTestData.FULL_ROOM;
import static com.tomer.scoundrel.achievements.AchievementsTestData.monster;
import static com.tomer.scoundrel.achievements.AchievementsTestData.potion;
import static com.tomer.scoundrel.achievements.AchievementsTestData.result;
import static com.tomer.scoundrel.achievements.AchievementsTestData.weapon;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Gathering the facts the achievement rules need from a run's events. */
class AchievementTrackerTest {

    /** A finished run's summary carries its outcome, score, final health and the seconds given. */
    @Test
    void capturesOutcomeScoreHealthAndSeconds() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(12, new GameEvent.GameWon(12)));

        assertTrue(tracker.isFinished());
        RunSummary summary = tracker.toSummary(87);
        assertEquals(Status.WON, summary.outcome());
        assertEquals(12, summary.score());
        assertEquals(12, summary.finalHealth());
        assertEquals(87, summary.seconds());
    }

    /** Final health is the health after the last move observed. */
    @Test
    void finalHealthIsTheLastObservedState() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(20, new GameEvent.MonsterDefeated(monster("6C", 6), false, 6)));
        tracker.observe(result(14, new GameEvent.MonsterDefeated(monster("2S", 2), false, 2)));
        tracker.observe(result(1, new GameEvent.GameWon(1)));

        assertEquals(1, tracker.toSummary(30).finalHealth());
    }

    /** The strongest bare-handed kill and the number of them are tracked, with weapon kills left out. */
    @Test
    void tracksHighestAndCountOfBareHandedKillsOnly() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(7, new GameEvent.MonsterDefeated(monster("KC", 13), false, 13)));
        // A weapon kill must not count toward the bare-handed tallies.
        tracker.observe(result(3,
                new GameEvent.MonsterDefeated(monster("AS", 14), true, 4),
                new GameEvent.WeaponDegraded(weapon(10), 14)));
        tracker.observe(result(0,
                new GameEvent.MonsterDefeated(monster("3C", 3), false, 3),
                new GameEvent.GameLost(-50)));

        RunSummary summary = tracker.toSummary(60);
        assertEquals(13, summary.highestBarehandedKill());
        assertEquals(2, summary.barehandedKillCount());
    }

    /** A full turn of three resolutions that kills a monster and takes no damage is flawless. */
    @Test
    void aFullRoomResolvedWithoutDamageIsFlawless() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(20, new GameEvent.WeaponEquipped(weapon(10))));
        tracker.observe(result(20,
                new GameEvent.MonsterDefeated(monster("5C", 5), true, 0),
                new GameEvent.WeaponDegraded(weapon(10), 5)));
        tracker.observe(result(20,
                new GameEvent.PotionUsed(potion(4), 0),
                new GameEvent.RoomDealt(List.of())));
        tracker.observe(result(20, new GameEvent.GameWon(20)));

        assertTrue(tracker.toSummary(40).flawlessRoom());
    }

    /** A full turn in which any damage was taken is not flawless. */
    @Test
    void aRoomInWhichAnyDamageWasTakenIsNotFlawless() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(14, new GameEvent.MonsterDefeated(monster("6C", 6), false, 6)));
        tracker.observe(result(14, new GameEvent.WeaponEquipped(weapon(8))));
        tracker.observe(result(14,
                new GameEvent.PotionUsed(potion(3), 0),
                new GameEvent.RoomDealt(List.of())));
        tracker.observe(result(14, new GameEvent.GameWon(14)));

        assertFalse(tracker.toSummary(40).flawlessRoom());
    }

    /** An avoided room is not flawless, though it cost no damage. */
    @Test
    void anAvoidedRoomIsNotFlawlessDespiteTakingNoDamage() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(20,
                new GameEvent.RoomAvoided(List.of()),
                new GameEvent.RoomDealt(List.of())));
        tracker.observe(result(20, new GameEvent.GameWon(20)));

        assertFalse(tracker.toSummary(40).flawlessRoom());
    }

    /** A scratchless final room of fewer than three resolutions does not count. */
    @Test
    void aScratchlessFinalPartialRoomDoesNotCount() {
        // The standard game ends in a 2-card room; clearing it without a scratch
        // resolves fewer than a full room, so Flawless Room deliberately stays out.
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(20, new GameEvent.MonsterDefeated(monster("2C", 2), true, 0)));
        tracker.observe(result(20,
                new GameEvent.MonsterDefeated(monster("2S", 2), true, 0),
                new GameEvent.GameWon(20)));

        assertFalse(tracker.toSummary(50).flawlessRoom());
    }

    /** A flawless room is found after an earlier room that took damage. */
    @Test
    void aFlawlessRoomAfterADamagedOneIsStillDetected() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        // Room one: a scratch is taken.
        tracker.observe(result(14, new GameEvent.MonsterDefeated(monster("6C", 6), false, 6)));
        tracker.observe(result(14, new GameEvent.WeaponEquipped(weapon(10))));
        tracker.observe(result(14,
                new GameEvent.PotionUsed(potion(3), 0),
                new GameEvent.RoomDealt(List.of())));
        // Room two: a full, scratchless room — detection is not limited to the first room.
        tracker.observe(result(14, new GameEvent.MonsterDefeated(monster("5C", 5), true, 0)));
        tracker.observe(result(14, new GameEvent.WeaponEquipped(weapon(9))));
        tracker.observe(result(14,
                new GameEvent.MonsterDefeated(monster("4C", 4), true, 0),
                new GameEvent.GameWon(14)));

        assertTrue(tracker.toSummary(80).flawlessRoom());
    }

    /** A flawless room still counts when the run later ends in a loss. */
    @Test
    void aFlawlessRoomEarnedBeforeDyingStillCounts() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        // A full, scratchless room latches the flag...
        tracker.observe(result(20, new GameEvent.MonsterDefeated(monster("5C", 5), true, 0)));
        tracker.observe(result(20, new GameEvent.WeaponEquipped(weapon(10))));
        tracker.observe(result(20,
                new GameEvent.MonsterDefeated(monster("4C", 4), true, 0),
                new GameEvent.RoomDealt(List.of())));
        // ...then a later room is fatal; the latch must survive into the loss.
        tracker.observe(result(0,
                new GameEvent.MonsterDefeated(monster("KC", 13), false, 13),
                new GameEvent.GameLost(-40)));

        RunSummary summary = tracker.toSummary(70);
        assertTrue(summary.flawlessRoom());
        assertEquals(Status.LOST, summary.outcome());
    }

    /** A damageless turn in which no monster was killed does not count. */
    @Test
    void aDamagelessRoomWithNoMonsterDoesNotCount() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(20, new GameEvent.WeaponEquipped(weapon(5))));
        tracker.observe(result(20, new GameEvent.WeaponEquipped(weapon(6))));
        tracker.observe(result(20,
                new GameEvent.PotionUsed(potion(4), 4),
                new GameEvent.RoomDealt(List.of())));
        tracker.observe(result(20, new GameEvent.GameWon(20)));

        assertFalse(tracker.toSummary(40).flawlessRoom());
    }

    /** Asking for the summary before the run has ended throws IllegalStateException. */
    @Test
    void toSummaryBeforeTheGameEndsThrows() {
        AchievementTracker tracker = new AchievementTracker(FULL_ROOM);
        tracker.observe(result(20, new GameEvent.PotionUsed(potion(5), 5)));

        assertFalse(tracker.isFinished());
        assertThrows(IllegalStateException.class, () -> tracker.toSummary(10));
    }
}
