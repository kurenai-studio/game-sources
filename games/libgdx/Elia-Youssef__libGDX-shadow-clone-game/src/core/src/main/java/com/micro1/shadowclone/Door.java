package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * A door that blocks the corridor while closed and passes bodies while open. Open state is driven by
 * required switches:
 *   GATED - open only while all required switches are active (so a clone must keep holding them).
 *   LATCH - opens the first time all required switches are active and then stays open.
 *
 * An {@code isExit} door is the level goal: reaching it while open completes the level.
 */
public final class Door {

    public enum Mode { GATED, LATCH }

    public final Rectangle rect = new Rectangle();
    public final String[] requiredSwitchIds;
    public final Mode mode;
    public final boolean isExit;

    public boolean open;
    private boolean latchedOpen;

    public Door(Mode mode, boolean isExit, float x, float y, float w, float h, String... requiredSwitchIds) {
        this.mode = mode;
        this.isExit = isExit;
        this.requiredSwitchIds = requiredSwitchIds;
        this.rect.set(x, y, w, h);
    }

    /** Recompute open state from the current switch states in {@code level}. */
    public void recompute(Level level) {
        boolean allActive = true;
        for (String id : requiredSwitchIds) {
            if (!level.isSwitchActive(id)) { allActive = false; break; }
        }
        if (mode == Mode.LATCH) {
            if (allActive) latchedOpen = true;
            open = latchedOpen;
        } else {
            open = allActive;
        }
    }

    /** Closed doors are solid barriers; open doors let bodies through. */
    public boolean blocks() {
        return !open;
    }

    public void reset() {
        open = false;
        latchedOpen = false;
    }
}
