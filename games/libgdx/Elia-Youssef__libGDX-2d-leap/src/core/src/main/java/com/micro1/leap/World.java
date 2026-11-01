package com.micro1.leap;

import com.badlogic.gdx.math.Rectangle;

/**
 * Pure gameplay state and simulation for Leap. This class holds no rendering
 * code and touches no Gdx statics, so it can be stepped headlessly and unit
 * tested without a window. GameScreen samples input, calls {@link #update}, then
 * draws purely from this state.
 *
 * Coordinate system: bottom-left, gameplay-world space. x increases right, y
 * increases up, y=0 is the bottom of the 800x560 play field.
 */
public class World {

    // Player size.
    public static final float PLAYER_W = 32f;
    public static final float PLAYER_H = 48f;

    // Spawn (bottom-left) on Platform 1.
    public static final float START_X = 40f;
    public static final float START_Y = 80f;

    // Movement / physics, all per-second and integrated with delta time.
    public static final float MOVE_SPEED = 200f;      // px/s horizontal
    public static final float JUMP_VELOCITY = 520f;   // px/s initial upward
    public static final float GRAVITY = 900f;         // px/s^2 downward

    // Level bounds.
    public static final float LEVEL_WIDTH = 3200f;
    public static final float LEVEL_HEIGHT = 560f;
    public static final float MAX_PLAYER_X = LEVEL_WIDTH - PLAYER_W; // 3168

    // Camera: the visible width is the 800px play field. The camera center x is
    // clamped so the visible left edge stays in [0, 2400].
    public static final float VIEW_WIDTH = 800f;
    public static final float CAM_MIN_X = VIEW_WIDTH / 2f;                // 400
    public static final float CAM_MAX_X = LEVEL_WIDTH - VIEW_WIDTH / 2f;  // 2800

    public enum State { PLAYING, WON }

    public final Level level = new Level();
    public final Player player = new Player();
    public State state = State.PLAYING;
    public float cameraX; // camera center x, world coordinates

    private final Rectangle playerRect = new Rectangle(0f, 0f, PLAYER_W, PLAYER_H);

    public World() {
        resetToStart();
    }

    /** Return the player and camera to the clean start state (fall reset / PLAY AGAIN). */
    public void resetToStart() {
        player.x = START_X;
        player.y = START_Y;
        player.vy = 0f;
        player.grounded = true;
        updateCamera();
    }

    /** Clear the win state and restart the level from a clean state. */
    public void playAgain() {
        state = State.PLAYING;
        resetToStart();
    }

    /**
     * Advance the simulation one frame.
     *
     * @param delta       frame time in seconds (delta-time integration)
     * @param left        move-left held this frame
     * @param right       move-right held this frame
     * @param jumpPressed jump edge: true only on the frame the jump key was first pressed
     */
    public void update(float delta, boolean left, boolean right, boolean jumpPressed) {
        if (state == State.WON) {
            return; // gameplay is frozen behind the win overlay
        }

        // Horizontal movement, then clamp the full rectangle inside the level.
        float vx = 0f;
        if (left) vx -= MOVE_SPEED;
        if (right) vx += MOVE_SPEED;
        player.x += vx * delta;
        if (player.x < 0f) player.x = 0f;
        if (player.x > MAX_PLAYER_X) player.x = MAX_PLAYER_X;

        // Jump only from the ground; no airborne re-jump.
        if (jumpPressed && player.grounded) {
            player.vy = JUMP_VELOCITY;
            player.grounded = false;
        }

        // Gravity and vertical integration. Remember the previous bottom edge so
        // landing can be detected as a swept crossing (no tunnelling at speed).
        player.vy -= GRAVITY * delta;
        float prevBottom = player.y;
        player.y += player.vy * delta;
        float newBottom = player.y;

        // Top-only landing: only while descending, only when the bottom edge
        // crosses a platform top from above within that platform's x-range.
        // Sides and undersides never block (upward / horizontal motion passes through).
        player.grounded = false;
        if (player.vy <= 0f) {
            for (Rectangle p : level.platforms) {
                float top = p.y + p.height;
                boolean xOverlap = player.x + PLAYER_W > p.x && player.x < p.x + p.width;
                if (xOverlap && prevBottom >= top && newBottom <= top) {
                    player.y = top;
                    player.vy = 0f;
                    player.grounded = true;
                    break;
                }
            }
        }

        // Fall below the play field -> immediate clean reset (no transition).
        if (player.y < 0f) {
            resetToStart();
            return;
        }

        // Goal overlap -> win immediately.
        playerRect.set(player.x, player.y, PLAYER_W, PLAYER_H);
        if (playerRect.overlaps(level.goal)) {
            state = State.WON;
        }

        updateCamera();
    }

    private void updateCamera() {
        float centerX = player.x + PLAYER_W / 2f;
        cameraX = clamp(centerX, CAM_MIN_X, CAM_MAX_X);
    }

    public static float clamp(float v, float min, float max) {
        if (v < min) return min;
        if (v > max) return max;
        return v;
    }
}
