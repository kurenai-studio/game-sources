package com.micro1.shadowclone;

import com.badlogic.gdx.utils.Array;

/**
 * Rolls the fixed 5 second recording window. Each step the live player's {@link InputFrame} is
 * appended to the current take and the timer advances; when the window closes {@link #record}
 * reports completion, the caller builds a {@link Recording} (frames + the pose the window started
 * from) to deploy a clone, then opens the next window with {@link #beginTake}.
 */
public final class Recorder {

    private final Array<InputFrame> take = new Array<>();
    private float timer;
    private float startX, startY, startVX, startVY;
    private int startFacing = 1;
    private boolean startOnGround;

    /** Open a fresh window anchored at the body's current pose AND motion (for exact replay). */
    public void beginTake(Body b) {
        take.clear();
        timer = 0f;
        startX = b.x;
        startY = b.y;
        startVX = b.vx;
        startVY = b.vy;
        startFacing = b.facing;
        startOnGround = b.onGround;
    }

    /** Append one step of input; returns true when the 5 s window has just filled. */
    public boolean record(InputFrame frame, float dt) {
        take.add(frame);
        timer += dt;
        return timer >= Theme.RECORD_SECONDS;
    }

    /** Snapshot the current take as an immutable Recording (copies the frame list). */
    public Recording buildRecording() {
        return new Recording(new Array<>(take), startX, startY, startVX, startVY, startFacing, startOnGround);
    }

    public float progress() {
        return Math.min(1f, timer / Theme.RECORD_SECONDS);
    }

    public float remainingSeconds() {
        return Math.max(0f, Theme.RECORD_SECONDS - timer);
    }
}
