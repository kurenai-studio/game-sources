package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Array;

/**
 * The one and only movement routine, run identically for the live player and every replaying clone.
 * Because a clone is advanced by exactly this code (fed recorded input instead of live input), it
 * re-experiences the environment during replay: conveyors push it, elevators/moving platforms carry
 * it, gravity and collision apply. Collision is axis-separated (resolve X, then Y) against the
 * level's solid platforms (carry-aware) and any closed doors (static barriers).
 */
public final class Physics {

    private Physics() {}

    public static void step(Body b, InputFrame in, Level level, float dt) {
        // Horizontal intent.
        float move = (in.left ? -1f : 0f) + (in.right ? 1f : 0f);
        b.vx = move * Theme.MOVE_SPEED;
        if (move != 0f) b.facing = move < 0f ? -1 : 1;

        // Jump (edge event) + gravity.
        if (in.jumpPressed && b.onGround) b.vy = Theme.JUMP_VELOCITY;
        b.vy += Theme.GRAVITY * dt;
        if (b.vy < Theme.MAX_FALL) b.vy = Theme.MAX_FALL;

        // Carry by the platform ridden last step (elevator/moving translation + conveyor push).
        Platform ride = b.ridingPlatform;
        float surface = 0f;
        if (ride != null && ride.solid) {
            b.x += ride.deltaX;
            b.y += ride.deltaY;
            surface = ride.surfaceVX;
        }

        // Horizontal integrate + resolve.
        float vxTotal = b.vx + surface;
        b.x += vxTotal * dt;
        resolveHorizontal(b, level, vxTotal);

        // Vertical integrate + resolve.
        b.onGround = false;
        b.ridingPlatform = null;
        b.y += b.vy * dt;
        resolveVertical(b, level);

        // Keep inside the screen horizontally (levels are single-screen).
        if (b.x < 0f) b.x = 0f;
        if (b.x + b.w > Theme.WORLD_W) b.x = Theme.WORLD_W - b.w;
    }

    private static void resolveHorizontal(Body b, Level level, float vxTotal) {
        Array<Platform> platforms = level.platforms;
        for (int i = 0; i < platforms.size; i++) {
            Platform p = platforms.get(i);
            if (!p.solid) continue;
            if (b.overlaps(p.bounds())) pushOutX(b, p.x, p.w, vxTotal);
        }
        Array<Door> doors = level.doors;
        for (int i = 0; i < doors.size; i++) {
            Door d = doors.get(i);
            if (d.blocks() && b.overlaps(d.rect)) pushOutX(b, d.rect.x, d.rect.width, vxTotal);
        }
    }

    private static void pushOutX(Body b, float px, float pw, float vxTotal) {
        if (vxTotal > 0f) {
            b.x = px - b.w;
        } else if (vxTotal < 0f) {
            b.x = px + pw;
        } else {
            float left = px - b.w;
            float right = px + pw;
            b.x = (Math.abs(b.x - left) < Math.abs(b.x - right)) ? left : right;
        }
    }

    private static void resolveVertical(Body b, Level level) {
        Array<Platform> platforms = level.platforms;
        for (int i = 0; i < platforms.size; i++) {
            Platform p = platforms.get(i);
            if (!p.solid) continue;
            if (b.overlaps(p.bounds())) {
                if (b.vy <= 0f) {
                    b.y = p.y + p.h;
                    b.vy = 0f;
                    b.onGround = true;
                    b.ridingPlatform = p;
                } else {
                    b.y = p.y - b.h;
                    b.vy = 0f;
                }
            }
        }
        Array<Door> doors = level.doors;
        for (int i = 0; i < doors.size; i++) {
            Door d = doors.get(i);
            if (!d.blocks()) continue;
            Rectangle r = d.rect;
            if (b.overlaps(r)) {
                if (b.vy <= 0f) {
                    b.y = r.y + r.height;
                    b.vy = 0f;
                    b.onGround = true;
                } else {
                    b.y = r.y - b.h;
                    b.vy = 0f;
                }
            }
        }
    }
}
