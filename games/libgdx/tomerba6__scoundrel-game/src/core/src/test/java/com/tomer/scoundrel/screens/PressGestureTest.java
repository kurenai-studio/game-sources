package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * A menu button acts on release, and the release only counts if it lands back on
 * the button the press started on — so a press can be taken back by sliding off,
 * which is what every desktop button has always done and what the board's
 * press-to-act cards deliberately do not.
 *
 * <p>The timing half of this is the reason it is a class and not three fields on
 * a screen: a click is often shorter than four frames, so acting the moment the
 * button comes up would cut to the next screen before the sunk plate had ever
 * been drawn. The press has to be <em>seen</em> before it is allowed to act.
 */
class PressGestureTest {

    private static final float FRAME = 1 / 60f;

    /** A press on a target sinks it and reports that it landed. */
    @Test
    void aPressSinksTheTargetItLandedOn() {
        PressGesture press = new PressGesture();
        assertTrue(press.press(2), "the press landed on something and should be consumed");
        assertEquals(2, press.sunk());
    }

    /** A press on nothing sinks nothing and reports a miss. */
    @Test
    void aPressThatMissesEverythingSinksNothing() {
        PressGesture press = new PressGesture();
        assertFalse(press.press(PressGesture.NONE));
        assertEquals(PressGesture.NONE, press.sunk());
    }

    /** Sliding off a held button lifts it. */
    @Test
    void slidingOffLiftsTheButtonBackUp() {
        PressGesture press = new PressGesture();
        press.press(1);
        press.moveOver(PressGesture.NONE);
        assertEquals(PressGesture.NONE, press.sunk());
    }

    /** Sliding onto a neighbour must not sink the neighbour — it is not held. */
    @Test
    void slidingOntoAnotherButtonSinksNeither() {
        PressGesture press = new PressGesture();
        press.press(1);
        press.moveOver(3);
        assertEquals(PressGesture.NONE, press.sunk());
    }

    /** Sliding back onto the held button sinks it again. */
    @Test
    void slidingBackOnSinksItAgain() {
        PressGesture press = new PressGesture();
        press.press(1);
        press.moveOver(PressGesture.NONE);
        press.moveOver(1);
        assertEquals(1, press.sunk());
    }

    /** Nothing is held, so drifting over a button while up must not sink it. */
    @Test
    void movingWithNothingHeldSinksNothing() {
        PressGesture press = new PressGesture();
        press.moveOver(2);
        assertEquals(PressGesture.NONE, press.sunk());
    }

    /** Releasing on the held button arms it, and it acts. */
    @Test
    void releasingOnTheHeldTargetActivatesIt() {
        PressGesture press = new PressGesture();
        press.press(2);
        assertTrue(press.release(2), "the release armed an action and should be consumed");
        assertEquals(2, fire(press));
    }

    /** Releasing after sliding off acts on nothing. */
    @Test
    void releasingAfterSlidingOffActivatesNothing() {
        PressGesture press = new PressGesture();
        press.press(2);
        press.moveOver(PressGesture.NONE);
        assertFalse(press.release(PressGesture.NONE));
        assertEquals(PressGesture.NONE, fire(press));
    }

    /** Releasing on a different button acts on neither. */
    @Test
    void releasingOnADifferentButtonActivatesNeither() {
        PressGesture press = new PressGesture();
        press.press(0);
        assertFalse(press.release(3));
        assertEquals(PressGesture.NONE, fire(press));
    }

    /** A release with nothing held acts on nothing. */
    @Test
    void aReleaseWithNothingHeldActivatesNothing() {
        PressGesture press = new PressGesture();
        assertFalse(press.release(1));
        assertEquals(PressGesture.NONE, fire(press));
    }

    /**
     * The point of the whole class. A press and release inside one frame still
     * holds the plate down long enough to be seen before it acts — otherwise a
     * fast click cuts to the next screen having drawn no feedback at all.
     */
    @Test
    void theSinkIsHeldLongEnoughToBeSeenBeforeItActs() {
        PressGesture press = new PressGesture();
        press.press(2);
        press.release(2);
        assertEquals(2, press.sunk(), "still down: the click has not been seen yet");

        float shown = 0f;
        for (int frame = 0; frame < 60; frame++) {
            int fired = press.advance(FRAME);
            if (fired != PressGesture.NONE) {
                assertEquals(2, fired);
                assertTrue(shown >= PressGesture.MIN_SINK,
                        "acted after only " + shown + "s of sunk plate");
                return;
            }
            assertEquals(2, press.sunk(), "the plate must stay down until it acts");
            shown += FRAME;
        }
        throw new AssertionError("the press never acted");
    }

    /** A press already held past the minimum acts on the very next frame. */
    @Test
    void aPressHeldPastTheMinimumActsAtOnce() {
        PressGesture press = new PressGesture();
        press.press(0);
        press.advance(1f);
        press.release(0);
        assertEquals(0, press.advance(FRAME));
    }

    /** Time spent slid off is not time the plate was down. */
    @Test
    void theSinkDoesNotAccrueWhileThePointerIsOff() {
        PressGesture press = new PressGesture();
        press.press(1);
        press.advance(FRAME);
        press.moveOver(PressGesture.NONE);
        for (int frame = 0; frame < 60; frame++) {
            assertEquals(PressGesture.NONE, press.advance(FRAME));
        }
        press.moveOver(1);
        press.release(1);
        assertEquals(PressGesture.NONE, press.advance(FRAME),
                "one frame of sink had been seen, not a second's worth");
    }

    /** A button acts once per click, then comes up. */
    @Test
    void aTargetActsOnlyOnce() {
        PressGesture press = new PressGesture();
        press.press(3);
        press.release(3);
        assertEquals(3, fire(press));
        for (int frame = 0; frame < 30; frame++) {
            assertEquals(PressGesture.NONE, press.advance(FRAME));
        }
        assertEquals(PressGesture.NONE, press.sunk());
    }

    /** Nothing held and nothing armed: advancing is free and reports nothing. */
    @Test
    void anIdleGestureNeverActs() {
        PressGesture press = new PressGesture();
        for (int frame = 0; frame < 30; frame++) {
            assertEquals(PressGesture.NONE, press.advance(FRAME));
        }
    }

    /**
     * A screen that goes modal mid-press — the first-run prompt closing over the
     * menu — drops the gesture rather than letting the old index act on whatever
     * now occupies it.
     */
    @Test
    void cancelDropsBothTheHoldAndAnArmedAction() {
        PressGesture press = new PressGesture();
        press.press(1);
        press.release(1);
        press.cancel();
        assertEquals(PressGesture.NONE, press.sunk());
        assertEquals(PressGesture.NONE, fire(press));
    }

    // --- a press that is already down (the click sound's guard) ------------------

    /** A held button, and only that one, is already down until it is released. */
    @Test
    void aHeldTargetIsAlreadyDownUntilItComesUp() {
        // One press delivered twice would play the menu click twice. A button
        // that is already down cannot go down again.
        PressGesture press = new PressGesture();
        assertFalse(press.alreadyDown(2), "nothing is down yet");
        press.press(2);
        assertTrue(press.alreadyDown(2));
        assertFalse(press.alreadyDown(3), "only the one it went down on");
        press.release(2);
        assertFalse(press.alreadyDown(2), "up again, so the next press is a new one");
    }

    /** A button slid off is still held, so it cannot go down again. */
    @Test
    void slidingOffDoesNotLetTheSameButtonGoDownAgain() {
        PressGesture press = new PressGesture();
        press.press(2);
        press.moveOver(PressGesture.NONE);
        assertTrue(press.alreadyDown(2), "still held, only lifted - no release came");
    }

    /** No target is never already down. */
    @Test
    void nothingIsAlreadyDownOnNothing() {
        PressGesture press = new PressGesture();
        press.press(PressGesture.NONE);
        assertFalse(press.alreadyDown(PressGesture.NONE));
    }

    /** After a cancel the button can go down again. */
    @Test
    void aCancelLetsTheButtonGoDownAfresh() {
        PressGesture press = new PressGesture();
        press.press(2);
        press.cancel();
        assertFalse(press.alreadyDown(2));
    }

    /** Runs frames until something acts, or gives up. */
    private static int fire(PressGesture press) {
        for (int frame = 0; frame < 60; frame++) {
            int fired = press.advance(FRAME);
            if (fired != PressGesture.NONE) {
                return fired;
            }
        }
        return PressGesture.NONE;
    }
}
