package com.tomer.scoundrel.audio;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Sounds held until their animation's beat, and flushed when an animation is cut short. */
class PendingCuesTest {

    private static final Sfx BLADE = new Sfx(Sound.BLADE, "blade_light_1", 1f, 1f);
    private static final Sfx THUD = new Sfx(Sound.THUD, "thud_light_1", 1f, 1f);
    private static final Sfx DRINK = new Sfx(Sound.DRINK, "drink_light_1", 1f, 1f);
    private static final Sfx FLIP_1 = new Sfx(Sound.FLIP, "flip_1", 1f, 1f);
    private static final Sfx FLIP_2 = new Sfx(Sound.FLIP, "flip_2", 1f, 1f);
    private static final Sfx FLIP_3 = new Sfx(Sound.FLIP, "flip_3", 1f, 1f);

    /** A cue is not due before its beat. */
    @Test
    void nothingIsDueBeforeItsBeat() {
        PendingCues cues = new PendingCues();
        cues.schedule(BLADE, 0.167f);
        assertEquals(List.of(), cues.due(0.1f));
        assertFalse(cues.isEmpty());
    }

    /** A cue comes due once its beat has passed, and only once. */
    @Test
    void aCueIsDueOnItsBeatAndOnlyOnce() {
        PendingCues cues = new PendingCues();
        cues.schedule(BLADE, 0.167f);
        assertEquals(List.of(BLADE), cues.due(0.2f));
        assertEquals(List.of(), cues.due(0.3f));
        assertTrue(cues.isEmpty());
    }

    /** A cue on beat zero is due at once. */
    @Test
    void aBeatAtZeroIsDueStraightAway() {
        PendingCues cues = new PendingCues();
        cues.schedule(BLADE, 0f);
        assertEquals(List.of(BLADE), cues.due(0f));
    }

    /** Cues sharing a beat come out in the order they were scheduled. */
    @Test
    void soundsSharingABeatComeOutInTheOrderTheyWereScheduled() {
        // A weapon kill's blade and thud are one moment; the blade leads.
        PendingCues cues = new PendingCues();
        cues.scheduleAll(List.of(BLADE, THUD), 0.167f);
        assertEquals(List.of(BLADE, THUD), cues.due(0.167f));
    }

    /** Due cues come out in beat order, whatever order they were scheduled in. */
    @Test
    void dueCuesComeOutInBeatOrderWhateverOrderTheyWereScheduled() {
        PendingCues cues = new PendingCues();
        cues.schedule(FLIP_2, 0.333f);
        cues.schedule(FLIP_1, 0.25f);
        assertEquals(List.of(FLIP_1, FLIP_2), cues.due(1f));
    }

    /** A flush hands over every pending cue once, in beat order, and empties the queue. */
    @Test
    void aFlushHandsOverEverythingStillPendingOnceAndEmptiesTheQueue() {
        PendingCues cues = new PendingCues();
        cues.schedule(DRINK, 0.417f);
        cues.schedule(BLADE, 0.167f);
        assertEquals(List.of(BLADE, DRINK), cues.flush());
        assertTrue(cues.isEmpty());
        assertEquals(List.of(), cues.flush());
        assertEquals(List.of(), cues.due(10f));
    }

    /** A flush leaves out cues that already came due. */
    @Test
    void aFlushDoesNotReplayWhatAlreadyPlayed() {
        PendingCues cues = new PendingCues();
        cues.schedule(BLADE, 0.167f);
        cues.schedule(DRINK, 0.417f);
        assertEquals(List.of(BLADE), cues.due(0.2f));
        assertEquals(List.of(DRINK), cues.flush());
    }

    /** A flush collapses a deal's flips to one, the earliest. */
    @Test
    void aSkippedDealIsOneFlipNotFour() {
        PendingCues cues = new PendingCues();
        cues.schedule(FLIP_1, 0.25f);
        cues.schedule(FLIP_2, 0.333f);
        cues.schedule(FLIP_3, 0.417f);
        cues.schedule(FLIP_1, 0.5f);
        assertEquals(List.of(FLIP_1), cues.flush());
    }

    /** Collapsing the flips keeps every other cue. */
    @Test
    void collapsingTheFlipsKeepsEverythingElse() {
        PendingCues cues = new PendingCues();
        cues.schedule(BLADE, 0.167f);
        cues.schedule(FLIP_2, 0.25f);
        cues.schedule(THUD, 0.167f);
        cues.schedule(FLIP_3, 0.333f);
        assertEquals(List.of(BLADE, THUD, FLIP_2), cues.flush());
    }

    /** A new queue is empty, with nothing due and nothing to flush. */
    @Test
    void aFreshQueueIsEmpty() {
        PendingCues cues = new PendingCues();
        assertTrue(cues.isEmpty());
        assertEquals(List.of(), cues.due(1f));
        assertEquals(List.of(), cues.flush());
    }
}
