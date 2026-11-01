package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * A laser beam hazard. Lethal on contact while emitting: a player who touches a live beam is reset
 * to the level start (item 37), a clone who touches one is destroyed (the "clone sacrifice" of the
 * Laser Corridor, item 36).
 *
 * A beam may be timed (fixed on/off interval with a visible cue, items 4/5) and may be disabled by a
 * controlling switch (a clone trips the switch to drop the beam so the player can pass).
 */
public final class Laser {

    public final Rectangle rect = new Rectangle();
    public String id;                   // optional, for switch timing gates
    public String controlId;            // switch that disables this beam (grid down / corridor trip)
    public boolean latchDisable;        // if true, once controlId fires the beam stays off for good
    public boolean disabledLatched;
    public boolean enabled = true;      // a switch can turn this false
    public boolean on = true;           // timed emitters toggle this
    public boolean lethalAtStepStart;   // snapshot so a clone that trips the disable still sacrifices

    // Timing (0 durations = always on).
    public final boolean timed;
    public final float onDuration;
    public final float offDuration;
    public float phase;                 // seconds into the on/off cycle

    private Laser(float x, float y, float w, float h, boolean timed, float onDur, float offDur, float phase) {
        this.rect.set(x, y, w, h);
        this.timed = timed;
        this.onDuration = onDur;
        this.offDuration = offDur;
        this.phase = phase;
    }

    public static Laser beam(float x, float y, float w, float h) {
        return new Laser(x, y, w, h, false, 0f, 0f, 0f);
    }

    public static Laser timed(float x, float y, float w, float h, float onDur, float offDur, float phase) {
        return new Laser(x, y, w, h, true, onDur, offDur, phase);
    }

    public void update(float dt) {
        if (timed) {
            float period = onDuration + offDuration;
            phase = (phase + dt) % period;
            on = phase < onDuration;
        }
    }

    /** Currently emitting and able to harm. */
    public boolean lethal() {
        return enabled && on;
    }

    public void reset() {
        enabled = true;
        on = true;
        phase = 0f;
        disabledLatched = false;
    }
}
