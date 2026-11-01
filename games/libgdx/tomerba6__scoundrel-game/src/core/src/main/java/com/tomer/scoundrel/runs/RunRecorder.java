package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameEvent;
import com.tomer.scoundrel.rules.MoveResult;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

/**
 * Observes one game from outside the engine — nothing is pushed; the caller
 * feeds it every {@link MoveResult} — and produces the {@link RunRecord}
 * once the game ends. Pure Java; the injected {@link Clock} keeps
 * timestamps and duration testable.
 */
public final class RunRecorder {

    private final Long seed;
    private final String rulesetId;
    private final Clock clock;
    private final Instant startedAt;

    private int monstersDefeated;
    private int damageTaken;
    private int healthHealed;
    private int potionsDrunk;
    private int potionsWasted;
    private int weaponsEquipped;
    private int roomsAvoided;
    private Status outcome;
    private int score;

    /**
     * Seed may be null for games started from an explicit dungeon order. The run's
     * clock starts now, so create it as the game is dealt.
     *
     * @param seed      the seed the game was shuffled from, or null
     * @param rulesetId the {@link com.tomer.scoundrel.rules.GameMode#id() mode id}, copied into
     *                  the record; non-blank, no whitespace
     * @param clock     where the start, end and elapsed time are read from; the game passes
     *                  {@link Clock#systemUTC()}, tests a fixed or stepped clock
     */
    public RunRecorder(Long seed, String rulesetId, Clock clock) {
        this.seed = seed;
        this.rulesetId = rulesetId;
        this.clock = clock;
        this.startedAt = clock.instant();
    }

    /**
     * Adds one move's events to the running totals, and notes the outcome when the
     * game ends. Call it with every result, in order.
     *
     * @param result what {@link com.tomer.scoundrel.rules.ScoundrelEngine#apply} returned
     */
    public void observe(MoveResult result) {
        for (GameEvent event : result.events()) {
            switch (event) {
                case GameEvent.MonsterDefeated m -> {
                    monstersDefeated++;
                    damageTaken += m.damageTaken();
                }
                case GameEvent.PotionUsed p -> {
                    potionsDrunk++;
                    healthHealed += p.healed();
                }
                case GameEvent.PotionWasted ignored -> potionsWasted++;
                case GameEvent.WeaponEquipped ignored -> weaponsEquipped++;
                case GameEvent.RoomAvoided ignored -> roomsAvoided++;
                case GameEvent.GameWon won -> {
                    outcome = Status.WON;
                    score = won.score();
                }
                case GameEvent.GameLost lost -> {
                    outcome = Status.LOST;
                    score = lost.score();
                }
                default -> { } // RoomDealt / WeaponDegraded add nothing to the totals
            }
        }
    }

    /**
     * Whether a win or a loss has been observed.
     *
     * @return true once {@link #toRecord} may be called
     */
    public boolean isFinished() {
        return outcome != null;
    }

    /**
     * Wall-clock seconds since the run began — drives the live HUD timer. Reads
     * the same injected clock as {@link #toRecord}, so it agrees with the
     * persisted {@link RunRecord#seconds()}.
     *
     * @return whole seconds elapsed, rounded down; still counting after the game ends
     */
    public long elapsedSeconds() {
        return Duration.between(startedAt, clock.instant()).getSeconds();
    }

    /**
     * Only valid once the observed game has ended.
     *
     * @return the finished run, ended and timed at the moment of this call
     * @throws IllegalStateException if no win or loss has been observed yet
     */
    public RunRecord toRecord() {
        if (!isFinished()) {
            throw new IllegalStateException("the run has not ended yet");
        }
        Instant ended = clock.instant();
        return new RunRecord(seed, rulesetId, outcome, score, ended,
                Duration.between(startedAt, ended).getSeconds(),
                monstersDefeated, damageTaken, healthHealed,
                potionsDrunk, potionsWasted, weaponsEquipped, roomsAvoided);
    }
}
