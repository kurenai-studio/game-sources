package com.tomer.scoundrel.screens;

/**
 * What ESC does on the board, where a run in progress is never left on one press.
 *
 * <p>It backs out of the innermost thing first, the way the ledger's erase
 * dialog does: the question, then the death still playing, then the chooser.
 * Only a run still being played is asked about. One that has ended is already
 * in the ledger, and the tutorial records nothing and has its own one-press
 * SKIP, so neither has anything to lose by leaving.
 */
final class BoardEscape {

    /** What one press of ESC does. */
    enum Action {
        /** Put the abandon-run question up. */
        ASK,
        /** Take the question down: ESC is the safe answer, as KEEP PLAYING is. */
        CLOSE_DIALOG,
        /** Close the move chooser, leaving its card unresolved. */
        CLOSE_CHOOSER,
        /** Skip the death to the end panel, as a click through it does. */
        SETTLE,
        /** To the title, as MAIN MENU and SKIP TUTORIAL go. */
        LEAVE
    }

    private BoardEscape() {
    }

    /**
     * What ESC does now, innermost first.
     *
     * @param asking       whether the abandon-run question is up
     * @param deathPlaying whether the death cinematic is still playing
     * @param runOver      whether the game is won or lost
     * @param chooserOpen  whether the move chooser is open on a card
     * @param tutorial     whether this board is the tutorial
     * @return the action for the first of those that holds, or {@link Action#ASK} mid-run
     */
    static Action of(boolean asking, boolean deathPlaying, boolean runOver,
                     boolean chooserOpen, boolean tutorial) {
        if (asking) {
            return Action.CLOSE_DIALOG;
        }
        if (deathPlaying) {
            return Action.SETTLE;
        }
        if (runOver) {
            return Action.LEAVE;
        }
        if (chooserOpen) {
            return Action.CLOSE_CHOOSER;
        }
        return tutorial ? Action.LEAVE : Action.ASK;
    }
}
