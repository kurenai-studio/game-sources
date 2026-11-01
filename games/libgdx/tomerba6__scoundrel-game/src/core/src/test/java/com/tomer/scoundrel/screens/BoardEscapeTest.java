package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

/**
 * What ESC does on the board. It backs out of the innermost thing first, and it
 * never throws away a run without asking — one stray press mid-run is easy to
 * make.
 */
class BoardEscapeTest {

    private static BoardEscape.Action press(boolean asking, boolean deathPlaying,
                                            boolean runOver, boolean chooserOpen,
                                            boolean tutorial) {
        return BoardEscape.of(asking, deathPlaying, runOver, chooserOpen, tutorial);
    }

    /** Mid-run, ESC asks before abandoning. */
    @Test
    void midRunItAsksBeforeAbandoning() {
        assertEquals(BoardEscape.Action.ASK, press(false, false, false, false, false));
    }

    /** A second ESC is the safe answer, as it is on the ledger's erase dialog. */
    @Test
    void withTheQuestionUpItClosesTheQuestion() {
        assertEquals(BoardEscape.Action.CLOSE_DIALOG, press(true, false, false, false, false));
        assertEquals(BoardEscape.Action.CLOSE_DIALOG, press(true, false, false, true, false),
                "the question sits over everything, the chooser included");
    }

    /** An open chooser closes first, in the tutorial too. */
    @Test
    void anOpenChooserClosesBeforeAnythingIsAsked() {
        assertEquals(BoardEscape.Action.CLOSE_CHOOSER, press(false, false, false, true, false));
        assertEquals(BoardEscape.Action.CLOSE_CHOOSER, press(false, false, false, true, true),
                "in the tutorial too");
    }

    /**
     * The run is already recorded by the time the death plays, so there is
     * nothing left to abandon: ESC does what a click does, and skips to the
     * end panel.
     */
    @Test
    void duringTheDeathItSkipsToTheEndPanel() {
        assertEquals(BoardEscape.Action.SETTLE, press(false, true, true, false, false));
        assertEquals(BoardEscape.Action.SETTLE, press(false, true, true, false, true));
    }

    /** A finished run has been recorded; leaving loses nothing, so nothing is asked. */
    @Test
    void onceTheRunIsOverItLeavesWithoutAsking() {
        assertEquals(BoardEscape.Action.LEAVE, press(false, false, true, false, false));
        assertEquals(BoardEscape.Action.LEAVE, press(false, false, true, false, true),
                "the tutorial's end panel too");
    }

    /** The tutorial records nothing, and its own SKIP already leaves in one press. */
    @Test
    void theTutorialLeavesWithoutAsking() {
        assertEquals(BoardEscape.Action.LEAVE, press(false, false, false, false, true));
    }

    /** Whatever else is true, a run in progress is never left without the question. */
    @Test
    void aRunInProgressIsNeverLeftWithoutAsking() {
        for (int bits = 0; bits < 32; bits++) {
            boolean asking = (bits & 1) != 0;
            boolean deathPlaying = (bits & 2) != 0;
            boolean runOver = (bits & 4) != 0;
            boolean chooserOpen = (bits & 8) != 0;
            boolean tutorial = (bits & 16) != 0;
            if (runOver || tutorial) {
                continue;
            }
            assertNotEquals(BoardEscape.Action.LEAVE,
                    press(asking, deathPlaying, runOver, chooserOpen, tutorial),
                    "left a live run without asking: bits " + bits);
        }
    }
}
