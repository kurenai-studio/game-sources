package com.micro1.tilemap;

import com.badlogic.gdx.math.Vector2;

/**
 * Pure (GL-free) player logic: world position, facing angle snapped to 0/90/180/270 degrees, and an
 * animation clock. {@link #move} reads four direction booleans (polled from the keyboard by
 * GameScreen), moves at a constant speed with axis-separated tile collision, faces the movement
 * direction, and advances the walk clock only while moving. No rendering lives here, so the whole
 * movement/facing/collision behaviour is unit-testable without a GL context.
 *
 * The supplied sprite is drawn facing East, and libGDX rotates counter-clockwise, so the four angles
 * map to: East = 0, North = 90, West = 180, South = 270.
 */
public class Player {

    /** Constant movement speed in world pixels per second (identical in every direction). */
    public static final float SPEED = 90f;
    /**
     * Collision half-box. Kept a little under a full tile so one-tile gaps stay passable (14px box vs
     * 16px tile), while sitting close enough to the drawn body that the sprite barely overlaps a wall
     * it is pressed against.
     */
    public static final float HALF_W = 7f;
    public static final float HALF_H = 7f;

    public final Vector2 pos = new Vector2();
    public float angleDeg = 0f;      // 0 = East (the sprite's drawn facing)
    public float stateTime = 0f;     // walk-animation clock, advanced only while moving
    public boolean moving = false;

    public Player(float startX, float startY) {
        pos.set(startX, startY);
    }

    /**
     * Advance one frame. dt is the frame delta in seconds. Movement is constant speed (diagonals are
     * normalized, so they are not faster), axis-separated against the collision layer so the player
     * slides along walls instead of sticking, and the facing snaps to one of the four cardinal angles.
     */
    public void move(boolean up, boolean down, boolean left, boolean right, float dt, TileCollision col) {
        int dx = (right ? 1 : 0) - (left ? 1 : 0);
        int dy = (up ? 1 : 0) - (down ? 1 : 0);
        moving = (dx != 0 || dy != 0);
        if (!moving) {
            return;
        }

        // constant speed regardless of a diagonal input combination
        float len = (float) Math.sqrt((double) (dx * dx + dy * dy));
        float vx = dx / len * SPEED;
        float vy = dy / len * SPEED;

        // face the movement direction, snapped to exactly 0/90/180/270 (horizontal wins on a diagonal)
        if (Math.abs(dx) >= Math.abs(dy)) {
            angleDeg = (dx > 0) ? 0f : 180f;
        } else {
            angleDeg = (dy > 0) ? 90f : 270f;
        }

        // axis-separated movement: try X, then Y, reverting each axis if its target box hits a wall
        float nx = pos.x + vx * dt;
        if (!col.boxBlocked(nx, pos.y, HALF_W, HALF_H)) {
            pos.x = nx;
        }
        float ny = pos.y + vy * dt;
        if (!col.boxBlocked(pos.x, ny, HALF_W, HALF_H)) {
            pos.y = ny;
        }

        stateTime += dt;
    }
}
