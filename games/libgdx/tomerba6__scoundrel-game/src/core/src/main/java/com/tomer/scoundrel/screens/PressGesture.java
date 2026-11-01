package com.tomer.scoundrel.screens;

/**
 * One press on a menu: which target is held, whether the pointer is still on it,
 * and how long the plate has been drawn down.
 *
 * <p>Menus act on <b>release</b>, and only if the release lands back on the
 * target the press started on — so a press can be taken back by sliding off,
 * which is what a button has always done. The board is the deliberate exception:
 * cards and the Avoid plate resolve on press, because a click made while the
 * mouse is already travelling to the next card is what fast play looks like and
 * release semantics silently discard it. The board hit-tests its
 * own rectangles for that, in {@code GameScreen.BoardInput}.
 *
 * <p>The timing is why this is a class rather than two fields on a screen.
 * A click is often shorter than four frames, and every menu button navigates, so
 * acting the instant the button comes up would cut to the next screen before the
 * sunk plate had been drawn once — release semantics would read as <em>less</em>
 * responsive than acting on press. So a release only arms the
 * action; {@link #advance} fires it once the plate has actually been on screen
 * for {@link #MIN_SINK}. Targets are whatever integers the screen hit-tests to,
 * matching the {@code -1} for nothing that {@link ScreenArt#buttonAt} returns.
 *
 * <p>Pure and headless — no LibGDX here, so the whole state machine is tested
 * rather than screenshotted.
 */
final class PressGesture {

    /** No target: the press missed, or nothing is held. */
    static final int NONE = -1;

    /**
     * How long the plate must be visibly down before the press may act. Four
     * frames at 60fps — enough to register as a click, short enough that the
     * menu does not feel like it is lagging behind the mouse.
     */
    static final float MIN_SINK = 0.06f;

    /** The target the press landed on, held until the button comes up. */
    private int held = NONE;
    /** Whether the pointer is currently back on {@link #held}. */
    private boolean inside;
    /** An armed action waiting for the sink to have been seen. */
    private int armed = NONE;
    /** Seconds the plate has actually been drawn down. */
    private float sunkFor;

    /** Creates a gesture with nothing held. */
    PressGesture() {
    }

    /**
     * The button went down over {@code target}.
     *
     * @param target what the screen hit-tested the press to, or {@link #NONE}
     * @return whether it landed on something, so the caller can consume the event
     */
    boolean press(int target) {
        held = target;
        inside = target != NONE;
        // Not reset while an action is still waiting to fire, or a second click
        // arriving inside 60ms would push the first one's sink back out again.
        if (armed == NONE) {
            sunkFor = 0f;
        }
        return inside;
    }

    /**
     * The pointer moved, and is now over {@code target}. Sliding off lifts the
     * plate; sliding back on puts it down again, rather than cancelling for
     * good — a wobble on the way to the click is not a change of mind.
     *
     * @param target what the pointer is over now, or {@link #NONE}
     */
    void moveOver(int target) {
        if (held != NONE) {
            inside = target == held;
        }
    }

    /**
     * The button came up over {@code target}.
     *
     * @param target what the pointer is over at release, or {@link #NONE}
     * @return whether that armed an action, so the caller can consume the event
     */
    boolean release(int target) {
        boolean acts = held != NONE && target == held;
        if (acts) {
            armed = held;
        }
        held = NONE;
        inside = false;
        return acts;
    }

    /** Drops the hold and anything armed — for a screen going modal mid-press. */
    void cancel() {
        held = NONE;
        inside = false;
        armed = NONE;
        sunkFor = 0f;
    }

    /**
     * Advances one frame and reports the target to activate now, or {@link #NONE}.
     *
     * <p>The fire is checked before the clock is added to, so {@code sunkFor} is
     * only ever the time the plate has already been <em>drawn</em> — input is
     * polled before the frame is rendered, so counting first would credit the
     * press with a frame nobody saw.
     *
     * @param delta seconds since the last frame
     * @return the target whose action fires now, or {@link #NONE}
     */
    int advance(float delta) {
        if (armed != NONE && sunkFor >= MIN_SINK) {
            int fired = armed;
            armed = NONE;
            sunkFor = 0f;
            return fired;
        }
        if (inside || armed != NONE) {
            sunkFor += delta;
        }
        return NONE;
    }

    /**
     * Whether {@code target} is already held down — pressed, and not yet released or
     * cancelled, whether or not the pointer is still on it. A button that is down
     * cannot go down again, so a press delivered twice clicks once.
     *
     * @param target the target a new press would land on
     * @return true if that target is held already; always false for {@link #NONE}
     */
    boolean alreadyDown(int target) {
        return target != NONE && held == target;
    }

    /**
     * Which target draws pressed this frame, or {@link #NONE}.
     *
     * @return the armed target if there is one, else the held one while the pointer is on it
     */
    int sunk() {
        if (armed != NONE) {
            return armed;
        }
        return inside ? held : NONE;
    }
}
