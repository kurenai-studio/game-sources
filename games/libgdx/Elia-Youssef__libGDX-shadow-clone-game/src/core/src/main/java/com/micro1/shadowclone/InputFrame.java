package com.micro1.shadowclone;

/**
 * One fixed-step slice of player intent. This is the unit the recorder captures and a clone
 * replays, so the clone repeats "what the player did" rather than "where the player was" - the
 * environment (conveyors, elevators, gravity) is re-applied through {@link Physics} during replay.
 *
 * Movement keys are stored as held state; jump and interact are stored as edge events (true only on
 * the exact step the key went down) so their timing replays precisely.
 */
public final class InputFrame {

    public final boolean left;
    public final boolean right;
    public final boolean jumpPressed;
    public final boolean interactPressed;

    public static final InputFrame NEUTRAL = new InputFrame(false, false, false, false);

    public InputFrame(boolean left, boolean right, boolean jumpPressed, boolean interactPressed) {
        this.left = left;
        this.right = right;
        this.jumpPressed = jumpPressed;
        this.interactPressed = interactPressed;
    }
}
