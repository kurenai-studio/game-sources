package com.micro1.shadowclash;

/**
 * A single frame's worth of "what this fighter wants to do", produced either by the keyboard
 * (player) or the {@link AIController} (CPU) and consumed by {@link Fighter#update}. Movement /
 * crouch / block are held signals; the attack and jump / back-dash are edge (press) signals.
 */
public final class Intent {
    public int moveDir;          // -1 left, 0 none, +1 right (held)
    public boolean run;          // hold a direction to run
    public boolean crouch;       // held
    public boolean jumpPressed;  // edge
    public boolean backDashPressed; // edge (double-tap on the player side)
    public boolean standBlock;   // held (M)
    public boolean crouchBlock;  // held (comma)
    public Move attack;          // an attack to start this frame, or null

    public void clear() {
        moveDir = 0;
        run = false;
        crouch = false;
        jumpPressed = false;
        backDashPressed = false;
        standBlock = false;
        crouchBlock = false;
        attack = null;
    }
}
