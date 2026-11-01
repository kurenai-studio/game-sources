package dev.luchoc.littlespaceship.core.domain.component;

/**
 * The player's persistent stats for the run.
 *
 * <p>None of these fields is touched when a life is lost, {@code lives} itself excepted: it is the
 * one thing {@code DamageSystem} decrements. {@code bombs} and {@code shotLevel} survive a death
 * exactly like any other persistent power-up, each consumed only by its own rule — the confirmed
 * correction in {@code 08-decisions-and-open-items.md} to the older draft that cleared everything.
 *
 * <p>{@code score} is never reduced by anything, including death: it is an arcade tally, not
 * another persistent power-up, and {@code 02-mvp-functional-spec.md} names no rule that would ever
 * subtract from it.
 *
 * <p>Exactly one entity holds this component: the player's ship.
 */
public final class Player {

    /** Lives remaining this run. Never negative. */
    public int lives;

    /** Bomb charges available. */
    public int bombs;

    /** Current weapon upgrade level, base included. */
    public int shotLevel;

    /** Points accumulated this run. Never negative, never decreases. */
    public int score;

    /**
     * Creates the player's stats, with the score a fresh run always starts at: zero.
     *
     * @param lives lives remaining
     * @param bombs bomb charges available
     * @param shotLevel current weapon upgrade level
     */
    public Player(int lives, int bombs, int shotLevel) {
        this.lives = lives;
        this.bombs = bombs;
        this.shotLevel = shotLevel;
        this.score = 0;
    }
}
