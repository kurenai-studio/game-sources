package com.tomer.scoundrel.achievements;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameEvent;
import com.tomer.scoundrel.rules.MoveResult;
import com.tomer.scoundrel.runs.RunRecord;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;

/** Fixtures shared by the achievement tests. */
final class AchievementsTestData {

    /** The standard ruleset's cardsResolvedPerTurn. */
    static final int FULL_ROOM = 3;

    private AchievementsTestData() {
    }

    /**
     * A clock that reads {@code start} first (the recorder's start) then {@code end}.
     *
     * @param start the first reading, taken as the run's start
     * @param end   every later reading
     * @return a UTC clock
     */
    static Clock advancingClock(Instant start, Instant end) {
        return new Clock() {
            private int calls;

            @Override
            public Instant instant() {
                return calls++ == 0 ? start : end;
            }

            @Override
            public ZoneId getZone() {
                return ZoneOffset.UTC;
            }

            @Override
            public Clock withZone(ZoneId zone) {
                return this;
            }
        };
    }

    /**
     * A MoveResult whose only state fact the tracker reads is health.
     *
     * @param health the health the state carries
     * @param events the events, in order
     * @return the result, its state otherwise empty and in progress
     */
    static MoveResult result(int health, GameEvent... events) {
        GameState state = new GameState(
                List.of(), List.of(), null, health, 0, 0, false, null, Status.IN_PROGRESS, null);
        return new MoveResult(state, List.of(events));
    }

    /**
     * A monster card.
     *
     * @param id    its id, as in {@code "KC"}
     * @param value its value; not checked
     * @return the card
     */
    static Card monster(String id, int value) {
        return new Card(id, CardType.MONSTER, value);
    }

    /**
     * A weapon card with a diamond id.
     *
     * @param value its value; not checked
     * @return the card, its id {@code value + "D"}
     */
    static Card weapon(int value) {
        return new Card(value + "D", CardType.WEAPON, value);
    }

    /**
     * A potion card with a heart id.
     *
     * @param value its value; not checked
     * @return the card, its id {@code value + "H"}
     */
    static Card potion(int value) {
        return new Card(value + "H", CardType.POTION, value);
    }

    /**
     * A run summary, its fields in the record's order.
     *
     * @param outcome               WON or LOST
     * @param score                 the final score
     * @param finalHealth           health after the last move
     * @param seconds               the run's length
     * @param highestBarehandedKill the strongest monster killed bare-handed, 0 if none
     * @param barehandedKillCount   how many monsters were killed bare-handed
     * @param flawlessRoom          whether some full turn killed a monster without damage
     * @return the summary
     */
    static RunSummary summary(Status outcome, int score, int finalHealth, long seconds,
                              int highestBarehandedKill, int barehandedKillCount, boolean flawlessRoom) {
        return new RunSummary(outcome, score, finalHealth, seconds,
                highestBarehandedKill, barehandedKillCount, flawlessRoom);
    }

    /**
     * A finished standard run for the history, its other counters zero.
     *
     * @param outcome  WON or LOST
     * @param score    its score
     * @param monsters monsters defeated in it
     * @return the record
     * @throws IllegalArgumentException if the outcome is IN_PROGRESS
     */
    static RunRecord run(Status outcome, int score, int monsters) {
        return new RunRecord(1L, "standard", outcome, score,
                Instant.parse("2026-07-06T10:00:00Z"), 120,
                monsters, 0, 0, 0, 0, 0, 0);
    }

    /**
     * An achievement context.
     *
     * @param run     the run just finished
     * @param history the recorded runs, oldest first
     * @return the context
     * @throws NullPointerException if a run in the history is null
     */
    static AchievementContext context(RunSummary run, RunRecord... history) {
        return new AchievementContext(run, List.of(history));
    }
}
