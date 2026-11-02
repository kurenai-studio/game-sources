package com.micro1.territory;

import com.badlogic.gdx.graphics.Color;

import java.util.Random;

/**
 * Pure (GL-free) game state machine: four rounds of START -> COUNTDOWN -> SELECT -> RESULT, then
 * FINAL. Holds the phase timers, competitor selections, CPU random picks, scoring, and winner
 * resolution. Deliberately free of rendering so it can be exercised headlessly.
 */
public class GameLogic {

    public static final float COUNTDOWN_TIME = 3f;
    public static final float SELECT_TIME = 3f;
    public static final int NUM_ROUNDS = 4;

    private final Round[] rounds;
    private final Competitor[] competitors; // [0]=You, [1]=CPU 1, [2]=CPU 2, [3]=CPU 3
    private final Random rng;

    private GamePhase phase = GamePhase.START;
    private int roundIndex = 0;      // 0-based index into rounds
    private float phaseTimer = 0f;   // seconds remaining in a timed phase
    private boolean scored = false;  // guards one scoring per round

    public GameLogic(Random rng) {
        if (rng == null) {
            throw new IllegalArgumentException("rng must not be null");
        }
        this.rng = rng;
        this.rounds = Rounds.build();
        this.competitors = new Competitor[]{
            new Competitor("You",   new Color(0.28f, 0.55f, 0.95f, 1f), false),
            new Competitor("CPU 1", new Color(0.90f, 0.32f, 0.32f, 1f), true),
            new Competitor("CPU 2", new Color(0.33f, 0.75f, 0.42f, 1f), true),
            new Competitor("CPU 3", new Color(0.96f, 0.68f, 0.20f, 1f), true),
        };
    }

    // --- inputs ---------------------------------------------------------------------------

    /** Start the game from the start screen. */
    public void pressStart() {
        if (phase == GamePhase.START) {
            beginRound(0);
        }
    }

    /** Advance from a round result to the next round (or the final screen). Debounced by phase. */
    public void pressNext() {
        if (phase != GamePhase.RESULT) {
            return;
        }
        if (roundIndex < rounds.length - 1) {
            beginRound(roundIndex + 1);
        } else {
            phase = GamePhase.FINAL;
        }
    }

    /**
     * Register a player click at a territory coordinate (100x60 space). Only affects the SELECT
     * phase; a click outside every territory is ignored (keeps the previous selection).
     */
    public void clickCoord(float cx, float cy) {
        if (phase != GamePhase.SELECT) {
            return;
        }
        Round r = currentRound();
        for (Territory ter : r.territories) {
            if (Geometry.contains(ter.polygon, cx, cy)) {
                competitors[0].selection = ter.index;
                return;
            }
        }
    }

    // --- update ---------------------------------------------------------------------------

    public void update(float dt) {
        if (dt <= 0f) {
            return;
        }

        // Consume overshoot across timed phases. A long frame must not silently extend either
        // three-second window (for example, update(6) covers countdown and selection exactly).
        float remaining = dt;
        while (remaining > 0f && (phase == GamePhase.COUNTDOWN || phase == GamePhase.SELECT)) {
            if (remaining < phaseTimer) {
                phaseTimer -= remaining;
                return;
            }

            remaining -= phaseTimer;
            if (phase == GamePhase.COUNTDOWN) {
                startSelect();
            } else {
                endSelect();
            }
        }
    }

    private void beginRound(int idx) {
        roundIndex = idx;
        scored = false;
        for (Competitor c : competitors) {
            c.selection = -1;
            c.roundScore = 0;
        }
        phase = GamePhase.COUNTDOWN;
        phaseTimer = COUNTDOWN_TIME;
    }

    private void startSelect() {
        phase = GamePhase.SELECT;
        phaseTimer = SELECT_TIME;
        // CPUs pick a random territory (0-3) for this round; the player picks by clicking.
        for (int i = 1; i < competitors.length; i++) {
            competitors[i].selection = rng.nextInt(currentRound().territories.length);
        }
    }

    private void endSelect() {
        phase = GamePhase.RESULT;
        phaseTimer = 0f;
        if (!scored) {
            int answer = currentRound().largestIndex;
            for (Competitor c : competitors) {
                c.roundScore = (c.selection == answer) ? 1 : 0;
                c.totalScore += c.roundScore;
            }
            scored = true;
        }
    }

    /**
     * Test/capture hook: force a specific phase, round and per-competitor selection/score state
     * for rendering a screenshot. Not used in normal play.
     */
    public void debugConfigure(GamePhase p, int roundIdx, int[] sel, int[] roundScore, int[] total) {
        this.phase = p;
        this.roundIndex = roundIdx;
        this.phaseTimer = p == GamePhase.COUNTDOWN ? COUNTDOWN_TIME
                : (p == GamePhase.SELECT ? SELECT_TIME : 0f);
        for (int i = 0; i < competitors.length; i++) {
            competitors[i].selection = sel[i];
            competitors[i].roundScore = roundScore[i];
            competitors[i].totalScore = total[i];
        }
    }

    // --- queries --------------------------------------------------------------------------

    public GamePhase phase() {
        return phase;
    }

    public Round currentRound() {
        return rounds[roundIndex];
    }

    public int roundNumber() {
        return roundIndex + 1;
    }

    public Competitor[] competitors() {
        return competitors;
    }

    public Competitor player() {
        return competitors[0];
    }

    /** Whole seconds to show on a countdown/selection timer (3,2,1 then 0). */
    public int timerSeconds() {
        return Math.max(0, (int) Math.ceil(phaseTimer - 0.0001f));
    }

    public float phaseTimer() {
        return phaseTimer;
    }

    /** Highest cumulative score across all competitors. */
    public int topScore() {
        int max = 0;
        for (Competitor c : competitors) {
            if (c.totalScore > max) {
                max = c.totalScore;
            }
        }
        return max;
    }

    /** True if this competitor is tied for the top score (including an all-zero tie). */
    public boolean isWinner(Competitor c) {
        return c.totalScore == topScore();
    }

    /**
     * Competitors ordered by cumulative score (descending); ties keep declaration order
     * (You, CPU 1, CPU 2, CPU 3), so You outranks a tied CPU as in the reference.
     */
    public Competitor[] ranking() {
        Competitor[] r = competitors.clone();
        for (int i = 1; i < r.length; i++) {
            Competitor key = r[i];
            int j = i - 1;
            while (j >= 0 && r[j].totalScore < key.totalScore) {
                r[j + 1] = r[j];
                j--;
            }
            r[j + 1] = key;
        }
        return r;
    }
}
