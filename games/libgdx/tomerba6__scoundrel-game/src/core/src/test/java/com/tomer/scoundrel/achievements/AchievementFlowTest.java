package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.Move;
import com.tomer.scoundrel.rules.MoveResult;
import com.tomer.scoundrel.rules.Ruleset;
import com.tomer.scoundrel.rules.Rulesets;
import com.tomer.scoundrel.rules.ScoundrelEngine;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.runs.RunRecorder;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.time.Clock;
import java.time.Instant;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;

import static com.tomer.scoundrel.achievements.AchievementsTestData.advancingClock;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * End-to-end over the real engine, mirroring GameScreen's finish flow headless:
 * observe a whole game, then evaluate and persist achievements from the summary
 * plus the run history. Proves the pieces compose against real event streams —
 * not just hand-built events.
 */
class AchievementFlowTest {

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    /**
     * Killing a King bare-handed to clear a one-card dungeon, through the real
     * engine and finish flow, unlocks exactly First Blood and Giant Slayer.
     */
    @Test
    void aBareHandedKingWinUnlocksFirstBloodAndGiantSlayer() {
        Ruleset rules = Rulesets.standard();
        ScoundrelEngine engine = new ScoundrelEngine(rules);
        RunLog runLog = new RunLog(dir.resolve("runs.log"));
        AchievementStore store = new AchievementStore(dir.resolve("achievements.log"));
        // A two-minute game, so Speedrunner (< 80s) does not also fire here.
        Clock clock = advancingClock(
                Instant.parse("2026-07-10T10:00:00Z"), Instant.parse("2026-07-10T10:02:00Z"));

        RunRecorder recorder = new RunRecorder(1L, "standard", clock);
        AchievementTracker tracker = new AchievementTracker(rules.cardsResolvedPerTurn());

        // A one-card dungeon: fight the King of clubs bare-handed and clear it.
        GameState state = engine.newGame(List.of(new Card("KC", CardType.MONSTER, 13)));
        MoveResult result = engine.apply(state, new Move.FightBarehanded(state.room().get(0)));
        recorder.observe(result);
        tracker.observe(result);
        assertEquals(Status.WON, result.state().status());

        // The finish flow, exactly as GameScreen runs it.
        RunRecord record = recorder.toRecord();
        runLog.append(record);
        RunSummary summary = tracker.toSummary(record.seconds());
        AchievementContext context = new AchievementContext(summary, runLog.readAll());
        List<Achievement> earned = AchievementService.newlyEarned(
                Achievements.all(), context, store.unlockedIds());
        for (Achievement achievement : earned) {
            store.append(new UnlockedAchievement(achievement.id(), record.endedAt()));
        }

        assertEquals(Set.of("first_blood", "giant_slayer"), store.unlockedIds());
    }

    /** An achievement already in the store is not earned again; only the new First Blood is. */
    @Test
    void alreadyUnlockedAchievementsAreNotEarnedAgain() {
        Ruleset rules = Rulesets.standard();
        ScoundrelEngine engine = new ScoundrelEngine(rules);
        AchievementStore store = new AchievementStore(dir.resolve("achievements.log"));
        store.append(new UnlockedAchievement("giant_slayer", Instant.parse("2026-07-01T00:00:00Z")));

        AchievementTracker tracker = new AchievementTracker(rules.cardsResolvedPerTurn());
        GameState state = engine.newGame(List.of(new Card("KC", CardType.MONSTER, 13)));
        MoveResult result = engine.apply(state, new Move.FightBarehanded(state.room().get(0)));
        tracker.observe(result);

        RunSummary summary = tracker.toSummary(120); // over 80s, so Speedrunner stays out of it
        AchievementContext context = new AchievementContext(summary,
                List.of(new RunRecord(1L, "standard", Status.WON, 7,
                        Instant.parse("2026-07-10T10:00:00Z"), 120, 1, 13, 0, 0, 0, 0, 0)));
        List<String> earned = AchievementService.newlyEarned(
                        Achievements.all(), context, store.unlockedIds())
                .stream().map(Achievement::id).toList();

        // First Blood is new; Giant Slayer was already held, so it is filtered out.
        assertEquals(List.of("first_blood"), earned);
    }
}
