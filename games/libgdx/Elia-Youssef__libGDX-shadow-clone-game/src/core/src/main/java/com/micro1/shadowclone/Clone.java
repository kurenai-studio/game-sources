package com.micro1.shadowclone;

/**
 * A holographic clone. It starts at its recording's start pose and, each fixed step, is advanced by
 * {@link Physics#step} using the next recorded {@link InputFrame}. After the recording ends it feeds
 * neutral input (stands still) but remains a physics body, so it keeps holding a switch it walked
 * onto yet is still carried by a conveyor it ends up on. It can be destroyed by a live laser
 * (the Laser Corridor sacrifice).
 */
public final class Clone extends Body {

    public final Recording recording;
    private int playhead;

    public Clone(Recording recording) {
        super(recording.startX, recording.startY, Theme.PLAYER_W, Theme.PLAYER_H);
        this.recording = recording;
        this.facing = recording.facing;
        this.vx = recording.startVX;         // start with the player's exact motion at window open,
        this.vy = recording.startVY;         //   so a mid-air hand-off replays frame-for-frame
        this.onGround = recording.startOnGround;
    }

    /** The input to feed physics this step; neutral once the recording is exhausted (then it holds). */
    public InputFrame next() {
        if (playhead < recording.length()) return recording.frames.get(playhead++);
        return InputFrame.NEUTRAL;
    }
}
