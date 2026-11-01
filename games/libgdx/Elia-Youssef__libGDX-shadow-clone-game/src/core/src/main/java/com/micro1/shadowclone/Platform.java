package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * A solid surface. One class covers every moving/static kind so {@link Physics} can resolve and
 * carry riders in one place:
 *   SOLID     - static floor/wall/ledge.
 *   CONVEYOR  - static surface that pushes riders horizontally ({@link #surfaceVX}).
 *   BRIDGE    - solid only while its controlling switch is held ({@link #solid} toggled by Level).
 *   ELEVATOR  - rises to {@link #topY} while active, sinks to {@link #baseY} otherwise; carries riders.
 *   MOVING    - ping-pongs between two points; carries riders.
 *
 * Each step the platform records its own movement as {@link #deltaX}/{@link #deltaY} so a rider can
 * be translated with it (items 34/35 elevator, 2/3 conveyor).
 */
public final class Platform {

    public enum Kind { SOLID, CONVEYOR, BRIDGE, ELEVATOR, MOVING }

    public final Kind kind;
    public float x, y, w, h;
    public boolean solid = true;
    public String controlId;         // BRIDGE solidity / ELEVATOR active are driven by this switch

    public float deltaX, deltaY;     // movement applied this step (for carrying riders)
    public float surfaceVX;          // conveyor horizontal push (px/s)

    // ELEVATOR params.
    public float baseY, topY, speed;
    public boolean active;           // set by Level from the controlling switch
    // MOVING params.
    private float ax, ay, bx, by, pathLen, t, dir = 1f;
    private float dwell, dwellTimer;  // pause at each endpoint (eases boarding a lift)

    private final Rectangle rect = new Rectangle();

    private Platform(Kind kind, float x, float y, float w, float h) {
        this.kind = kind;
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
    }

    // --- Factories (keep Levels readable). ---------------------------------------------------
    public static Platform solid(float x, float y, float w, float h) {
        return new Platform(Kind.SOLID, x, y, w, h);
    }

    public static Platform conveyor(float x, float y, float w, float h, float surfaceVX) {
        Platform p = new Platform(Kind.CONVEYOR, x, y, w, h);
        p.surfaceVX = surfaceVX;
        return p;
    }

    /** A bridge span; starts non-solid until its switch is held. */
    public static Platform bridge(float x, float y, float w, float h) {
        Platform p = new Platform(Kind.BRIDGE, x, y, w, h);
        p.solid = false;
        return p;
    }

    public static Platform elevator(float x, float baseY, float w, float h, float topY, float speed) {
        Platform p = new Platform(Kind.ELEVATOR, x, baseY, w, h);
        p.baseY = baseY;
        p.topY = topY;
        p.speed = speed;
        return p;
    }

    public static Platform moving(float x, float y, float w, float h, float toX, float toY, float speed) {
        Platform p = new Platform(Kind.MOVING, x, y, w, h);
        p.ax = x; p.ay = y; p.bx = toX; p.by = toY;
        p.speed = speed;
        p.pathLen = Math.max(1f, (float) Math.hypot(toX - x, toY - y));
        return p;
    }

    /** Fluent: link this bridge/elevator to a controlling switch id. */
    public Platform controlledBy(String switchId) {
        this.controlId = switchId;
        return this;
    }

    /** Fluent: make a MOVING platform pause this many seconds at each endpoint. */
    public Platform withDwell(float seconds) {
        this.dwell = seconds;
        return this;
    }

    /** Advance any motion for this step; {@code active} only affects elevators. */
    public void update(float dt) {
        float prevX = x, prevY = y;
        switch (kind) {
            case ELEVATOR: {
                float target = active ? topY : baseY;
                if (y < target) y = Math.min(target, y + speed * dt);
                else if (y > target) y = Math.max(target, y - speed * dt);
                break;
            }
            case MOVING: {
                if (dwellTimer > 0f) {
                    dwellTimer -= dt;    // paused at an endpoint
                } else {
                    t += dir * (speed / pathLen) * dt;
                    if (t >= 1f) { t = 1f; dir = -1f; dwellTimer = dwell; }
                    else if (t <= 0f) { t = 0f; dir = 1f; dwellTimer = dwell; }
                    x = ax + (bx - ax) * t;
                    y = ay + (by - ay) * t;
                }
                break;
            }
            default:
                break;
        }
        deltaX = x - prevX;
        deltaY = y - prevY;
    }

    public Rectangle bounds() {
        rect.set(x, y, w, h);
        return rect;
    }

}
