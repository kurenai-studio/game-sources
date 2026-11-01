package com.micro1.shadowclone;

import com.badlogic.gdx.utils.Array;

/**
 * An immutable take: the ordered {@link InputFrame}s captured during one 5 second window plus the
 * player's pose at the moment the window opened. A {@link Clone} is deployed from a Recording and
 * replays the frames in order starting from {@code startX, startY} (item 27: "repeats the player's
 * stored movement path, jumps, and interactions using the original sequence timing").
 */
public final class Recording {

    public final Array<InputFrame> frames;
    public final float startX;
    public final float startY;
    public final float startVX;      // velocity at the moment the window opened, so a clone whose
    public final float startVY;      //   window began mid-motion replays frame-exactly (item 27)
    public final boolean startOnGround;
    public final int facing;         // -1 left, +1 right at the moment recording started

    public Recording(Array<InputFrame> frames, float startX, float startY,
                     float startVX, float startVY, int facing, boolean startOnGround) {
        this.frames = frames;
        this.startX = startX;
        this.startY = startY;
        this.startVX = startVX;
        this.startVY = startVY;
        this.facing = facing;
        this.startOnGround = startOnGround;
    }

    public int length() {
        return frames.size;
    }
}
