package com.tomer.scoundrel.tutorial;

import com.tomer.scoundrel.rules.Move;

/**
 * One beat of the tutorial: a line of narration and either the move the player
 * must make to advance (an <em>action</em> step) or nothing (an
 * <em>explanation</em> step, advanced by the reader). Pure data — the screen
 * shows the narration, highlights the move's target, and gates input on it.
 *
 * @param narration    what the callout says, in sentence case; the screen wraps it
 * @param expectedMove the one move that advances this beat, or null for an explanation
 */
public record TutorialStep(String narration, Move expectedMove) {

    /**
     * An explanation-only beat: no move to make; advanced by a Next click.
     *
     * @param narration what the callout says
     * @return a step with no expected move
     */
    public static TutorialStep say(String narration) {
        return new TutorialStep(narration, null);
    }

    /**
     * An action beat: advanced only by making {@code move}.
     *
     * @param narration what the callout says, usually naming the move
     * @param move      the move the player must make; it must be legal at this point in the
     *                  scripted game, which {@code TutorialScriptTest} plays through to check
     * @return a step expecting {@code move}
     */
    public static TutorialStep act(String narration, Move move) {
        return new TutorialStep(narration, move);
    }

    /**
     * True when the player must make a move here; false for explanation beats.
     *
     * @return whether {@code expectedMove} is set
     */
    public boolean isAction() {
        return expectedMove != null;
    }
}
