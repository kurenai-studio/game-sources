package dev.luchoc.littlespaceship.core.port;

/**
 * The end-of-level bonus per {@code 10-mvp-initial-values.md}: a fixed amount per remaining life
 * and per remaining bomb, no combos or multipliers involved — the same rule {@code
 * ScoreSystem.completionBonus} computes, split into the two rows the Victory screen shows.
 *
 * <p>Reflects the player's current lives and bombs regardless of {@link LevelOutcome}, the same way
 * {@link PlayerStatus#score()} does; whoever reads this decides when the number is meaningful,
 * typically once {@link WorldView#outcome()} reports {@link LevelOutcome#COMPLETED}.
 *
 * @param livesBonus the bonus earned from remaining lives, {@code lives * lifeCompletionBonus}
 * @param bombsBonus the bonus earned from remaining bombs, {@code bombs * bombCompletionBonus}
 */
public record CompletionBonus(int livesBonus, int bombsBonus) {

    /** The total of both bonuses, for whoever wants one number instead of two. */
    public int total() {
        return livesBonus + bombsBonus;
    }
}
