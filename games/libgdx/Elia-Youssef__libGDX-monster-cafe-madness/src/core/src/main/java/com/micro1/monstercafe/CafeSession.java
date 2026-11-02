package com.micro1.monstercafe;

import java.util.Random;

/**
 * The pure gameplay model for Monster Cafe Madness: the score, the customer happiness, the single active
 * monster and its requested food, and the win/loss status. Contains NO libGDX ({@code Gdx.*}) references, so
 * every rule here is unit-testable headlessly. The screens are a thin view/input layer over this class.
 *
 * <p>Rules (from the task prompt):
 * <ul>
 *   <li>Score starts at 0; each correct serve adds exactly {@value #POINTS_PER_CORRECT}.</li>
 *   <li>Happiness starts at {@value #START_HAPPINESS} percent; each wrong serve subtracts exactly
 *       {@value #HAPPINESS_PENALTY}. Correct serves never change happiness.</li>
 *   <li>Reaching {@value #WIN_SCORE} points wins; happiness reaching 0 loses.</li>
 *   <li>A correct serve advances to a new random monster + order; a wrong serve keeps the same customer.</li>
 * </ul>
 */
public class CafeSession {

    /** Points awarded for each correctly served order. */
    public static final int POINTS_PER_CORRECT = 10;
    /** Happiness (percent) lost on each incorrect order. */
    public static final int HAPPINESS_PENALTY = 20;
    /** Happiness (percent) at the start of a session. */
    public static final int START_HAPPINESS = 100;
    /** Score that wins the game. */
    public static final int WIN_SCORE = 100;

    /** High-level state of a session. */
    public enum Status { PLAYING, WON, LOST }

    /** Outcome of a single {@link #serve(FoodType)} call, so the view can advance, transition, or ignore. */
    public enum ServeResult { CORRECT, WRONG, WIN, LOSE, IGNORED }

    // Cached once so spawning an order allocates no throwaway arrays.
    private static final MonsterType[] MONSTERS = MonsterType.values();
    private static final FoodType[] FOODS = FoodType.values();

    private final Random rng;

    private int score;
    private int happiness;
    private MonsterType currentMonster;
    private FoodType requestedFood;
    private Status status;

    /** Uses a fresh random source. */
    public CafeSession() {
        this(new Random());
    }

    /** Uses a supplied random source (deterministic for tests). */
    public CafeSession(Random rng) {
        this.rng = rng;
        start();
    }

    /**
     * (Re)start a session from the initial state: score 0, happiness 100, PLAYING, and a fresh random
     * monster + requested food. Called by the constructor and on every restart, so no stale state carries
     * over between sessions.
     */
    public void start() {
        score = 0;
        happiness = START_HAPPINESS;
        status = Status.PLAYING;
        spawnNextOrder();
    }

    /** Pick a new random monster and a new random requested food (uniform, independent, may repeat). */
    private void spawnNextOrder() {
        currentMonster = MONSTERS[rng.nextInt(MONSTERS.length)];
        requestedFood = FOODS[rng.nextInt(FOODS.length)];
    }

    /**
     * Serve the given food to the active monster.
     * <ul>
     *   <li>Not PLAYING (already WON or LOST): does nothing, returns {@link ServeResult#IGNORED}.</li>
     *   <li>Correct: +10 score, happiness unchanged; if the score reaches {@value #WIN_SCORE} the game is
     *       WON, otherwise a new random monster + order appears.</li>
     *   <li>Wrong: score unchanged, happiness -20; if happiness reaches 0 the game is LOST, otherwise the
     *       same monster keeps waiting with the same order.</li>
     * </ul>
     */
    public ServeResult serve(FoodType chosen) {
        if (status != Status.PLAYING) {
            return ServeResult.IGNORED;
        }
        if (chosen == requestedFood) {
            score += POINTS_PER_CORRECT;
            if (score >= WIN_SCORE) {
                status = Status.WON;
                return ServeResult.WIN;
            }
            spawnNextOrder();
            return ServeResult.CORRECT;
        } else {
            happiness -= HAPPINESS_PENALTY;
            if (happiness <= 0) {
                happiness = 0;
                status = Status.LOST;
                return ServeResult.LOSE;
            }
            return ServeResult.WRONG;
        }
    }

    public int getScore() { return score; }
    public int getHappiness() { return happiness; }
    public MonsterType getCurrentMonster() { return currentMonster; }
    public FoodType getRequestedFood() { return requestedFood; }
    public Status getStatus() { return status; }
    public boolean isPlaying() { return status == Status.PLAYING; }
    public boolean isWon() { return status == Status.WON; }
    public boolean isLost() { return status == Status.LOST; }
}
