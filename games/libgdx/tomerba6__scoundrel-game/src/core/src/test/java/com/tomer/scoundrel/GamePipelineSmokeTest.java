package com.tomer.scoundrel;

import com.tomer.scoundrel.achievements.Achievement;
import com.tomer.scoundrel.achievements.AchievementContext;
import com.tomer.scoundrel.achievements.AchievementService;
import com.tomer.scoundrel.achievements.AchievementTracker;
import com.tomer.scoundrel.achievements.Achievements;
import com.tomer.scoundrel.achievements.RunSummary;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameMode;
import com.tomer.scoundrel.rules.GameModes;
import com.tomer.scoundrel.rules.Move;
import com.tomer.scoundrel.rules.MoveResult;
import com.tomer.scoundrel.rules.ScoundrelEngine;
import com.tomer.scoundrel.runs.HighScores;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.runs.RunRecord;
import com.tomer.scoundrel.runs.RunRecorder;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Path;
import java.time.Clock;
import java.util.List;
import java.util.Random;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Headless smoke test of everything the app does over a full game <em>except</em>
 * rendering: every random-but-legal game across every mode is driven through
 * the real observer + persistence + achievement pipeline exactly as
 * {@code GameScreen.applyMove}/{@code finishRun} wire it — the {@link RunRecorder}
 * and {@link AchievementTracker} watch each {@link MoveResult}, then at game end
 * the record is built, high-scored, persisted through the tolerant {@link RunLog},
 * and, in Standard (the one mode that counts them), achievements are evaluated.
 * It asserts the whole chain never throws and stays self-consistent, so an
 * integration regression between the engine and its observers surfaces here
 * rather than only in a hand-run of the game.
 *
 * <p>The drawing layer above this (the actual rendering, animations, and input
 * routing in {@code GameScreen}) is GL-bound and is verified by screenshot
 * instead; this covers the non-visual pipeline it sits on.
 */
class GamePipelineSmokeTest {

    private static final int GAMES_PER_MODE = 60;

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    /**
     * Sixty random legal games in each mode run through the whole non-visual
     * pipeline, and each record matches its game and reads back from the log.
     */
    @Test
    void everyModePlaysFullGamesThroughTheObserverAndPersistencePipeline() {
        RunLog runLog = new RunLog(dir.resolve("runs.log"));
        for (GameMode mode : GameModes.all()) {
            ScoundrelEngine engine = new ScoundrelEngine(mode.ruleset());
            for (int seed = 0; seed < GAMES_PER_MODE; seed++) {
                playThroughPipeline(engine, mode, runLog, seed);
            }
        }
    }

    private void playThroughPipeline(ScoundrelEngine engine, GameMode mode, RunLog runLog, long seed) {
        Random rng = new Random(seed);
        GameState state = engine.newGame(seed);
        RunRecorder recorder = new RunRecorder(seed, mode.id(), Clock.systemUTC());
        AchievementTracker tracker = new AchievementTracker(mode.ruleset().cardsResolvedPerTurn());

        // Play the game, feeding every result to both observers — as the UI does.
        while (state.status() == Status.IN_PROGRESS) {
            List<Move> moves = engine.legalMoves(state);
            MoveResult result = engine.apply(state, moves.get(rng.nextInt(moves.size())));
            recorder.observe(result);
            tracker.observe(result);
            state = result.state();
        }

        // The finishRun pipeline: record, high-score, persist, re-read, evaluate.
        assertTrue(recorder.isFinished(), "recorder did not see the game end (seed " + seed + ")");
        RunRecord record = recorder.toRecord();
        assertEquals(state.status(), record.outcome(), "record outcome disagrees (seed " + seed + ")");
        assertEquals(state.score().intValue(), record.score(), "record score disagrees (seed " + seed + ")");
        assertEquals(mode.id(), record.rulesetId());

        HighScores.bestForRuleset(runLog.readAll(), mode.id()); // must not throw on the growing log
        runLog.append(record);
        List<RunRecord> history = runLog.readAll();
        assertEquals(record, history.get(history.size() - 1),
                "the run did not round-trip through the log (seed " + seed + ")");

        // Achievements are evaluated only for the ranked mode, as in the app.
        if (mode.tracksAchievements()) {
            RunSummary summary = tracker.toSummary(record.seconds());
            AchievementContext context = new AchievementContext(summary, history);
            List<Achievement> earned = AchievementService.newlyEarned(
                    Achievements.all(), context, Set.of());
            assertNotNull(earned, "achievement evaluation returned null (seed " + seed + ")");
            assertTrue(Achievements.all().containsAll(earned),
                    "earned an achievement not in the catalog (seed " + seed + ")");
        }
    }
}
