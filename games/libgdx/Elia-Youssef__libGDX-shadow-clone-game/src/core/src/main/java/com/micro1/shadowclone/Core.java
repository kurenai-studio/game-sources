package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * The facility power core (Clone Core level, items 12/13). Four overload plates (A/B/C/D) must be
 * held at once; while all four are held the redirect terminal can be triggered to route power, which
 * flips the core to STABILIZED (a visible state change) and opens the exit. Stability climbs toward
 * 100% while overloads are held and is shown in the CORE STATUS panel.
 */
public final class Core {

    public final Rectangle rect = new Rectangle();
    public float stability = 42f;        // percent, mirrors the reference CORE STATUS readout
    public boolean allOverloaded;        // all four plates held this step
    public boolean powerRouted;          // redirect terminal fired while overloaded
    public boolean stabilized;           // final state change

    public Core(float x, float y, float w, float h) {
        rect.set(x, y, w, h);
    }

    /** @param overloadCount plates held (0..4), @param redirectPressed redirect terminal active. */
    public void update(int overloadCount, boolean redirectPressed, float dt) {
        allOverloaded = overloadCount >= 4;
        if (allOverloaded) {
            stability = Math.min(100f, stability + 22f * dt);
            if (redirectPressed) powerRouted = true;
        } else {
            stability = Math.max(15f, stability - 10f * dt);
        }
        if (powerRouted && stability >= 80f) stabilized = true;
    }

    public String statusLabel() {
        if (stabilized) return "STABILIZED";
        if (powerRouted) return "POWER ROUTED";
        if (allOverloaded) return "OVERLOADING";
        return "PROTECTED";
    }

    public void reset() {
        stability = 42f;
        allOverloaded = false;
        powerRouted = false;
        stabilized = false;
    }
}
