package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * A switch the player or a clone can activate.
 *   PLATE    - a pressure pad: active while any body stands on / overlaps it (recomputed each step).
 *   TERMINAL - a console: latches active when a body presses interact while overlapping it, and
 *              stays active (a clone that replays the interact press can hold it forever).
 *
 * The clone activating and maintaining switches independently of the player is the backbone of the
 * puzzle rubric (items 29/30/31/32/34/38...).
 */
public final class Switch {

    public enum Kind { PLATE, TERMINAL }

    public final Kind kind;
    public final String id;
    public final Rectangle rect = new Rectangle();
    public final String label;
    public String requiresLaserOff;     // TERMINAL: can only latch while this laser is off (timed switch)
    public boolean hidden;              // synthetic switch (e.g. CORE_DONE); not drawn

    public boolean active;
    public boolean latched;         // TERMINAL memory
    public boolean justActivated;   // rising edge this step (for stat counting)

    public Switch(Kind kind, String id, String label, float x, float y, float w, float h) {
        this.kind = kind;
        this.id = id;
        this.label = label;
        this.rect.set(x, y, w, h);
    }

    public static Switch plate(String id, String label, float x, float y, float w) {
        return new Switch(Kind.PLATE, id, label, x, y, w, 14f);
    }

    public static Switch terminal(String id, String label, float x, float y) {
        return new Switch(Kind.TERMINAL, id, label, x, y, 34f, 48f);
    }

    public void reset() {
        active = false;
        latched = false;
        justActivated = false;
    }
}
