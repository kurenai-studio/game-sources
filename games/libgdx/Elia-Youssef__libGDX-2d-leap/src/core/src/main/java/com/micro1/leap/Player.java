package com.micro1.leap;

/**
 * Mutable player state. Position is the bottom-left corner in gameplay-world
 * coordinates; the size is fixed (see {@link World#PLAYER_W} / PLAYER_H).
 * vy is the vertical velocity; horizontal velocity is derived from input each
 * frame and is not stored. grounded is true only while resting on a platform top.
 */
public class Player {
    public float x;
    public float y;
    public float vy;
    public boolean grounded;
}
