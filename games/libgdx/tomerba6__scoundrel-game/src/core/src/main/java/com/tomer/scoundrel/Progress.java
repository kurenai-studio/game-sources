package com.tomer.scoundrel;

import com.tomer.scoundrel.achievements.AchievementStore;
import com.tomer.scoundrel.runs.RunLog;
import com.tomer.scoundrel.tutorial.TutorialFlag;

/**
 * The progress-reset composition: erasing all recorded runs, earned
 * achievements and the tutorial-seen marker together. Pure and headless (no
 * LibGDX), so the "wipe every store" contract the reset feature promises can be
 * unit-tested — {@link ScoundrelGame#eraseAllProgress()} is a thin delegate to
 * this. Lives in the composition root because it spans {@code runs},
 * {@code achievements} and {@code tutorial}, and the only import between those
 * three runs one way ({@code achievements} reads the run log). Housing the
 * reset in any of them would add an import it does not have today — and in
 * {@code runs}, a cycle.
 */
public final class Progress {

    private Progress() {
    }

    /**
     * Wipes the run history, the unlocked-achievement latch, and the
     * tutorial-seen marker (so a full reset makes the player new again). Each
     * {@code clear()} is a recoverable soft-delete — the file is moved aside to a
     * {@code .bak} sibling — so an accidental reset stays recoverable from disk.
     *
     * @param runLog       the run history to clear
     * @param achievements the unlocked latch to clear
     * @param tutorial     the tutorial-seen marker to clear
     * @throws java.io.UncheckedIOException if a file cannot be moved; the stores are cleared
     *                                      in the order given, so earlier ones stay cleared
     */
    public static void eraseAll(RunLog runLog, AchievementStore achievements, TutorialFlag tutorial) {
        runLog.clear();
        achievements.clear();
        tutorial.clear();
    }
}
