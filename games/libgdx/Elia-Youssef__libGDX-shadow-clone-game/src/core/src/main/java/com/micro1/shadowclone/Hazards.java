package com.micro1.shadowclone;

import com.badlogic.gdx.math.Rectangle;

/**
 * Pure hazard resolution shared by {@link PlayScreen} and the headless test harness (no graphics).
 * Lasers block the live player (a minimum-translation push-out, so accidental contact never wipes
 * progress - item 37 "block / prevent progression") but destroy clones that touch a live beam
 * (the Laser Corridor sacrifice, item 36). A fall below the world is a pit death.
 */
public final class Hazards {

    public static final float PIT_Y = -60f;

    private Hazards() {}

    /** True if this clone touched a beam that was live at the start of the step (should be removed). */
    public static boolean cloneHitByLaser(Level level, Clone clone) {
        for (Laser l : level.lasers) {
            if (l.lethalAtStepStart && clone.overlaps(l.rect)) return true;
        }
        return false;
    }

    /** Push the player out of any currently live beam along the shallower axis. */
    public static void blockPlayerAtLasers(Level level, Player player) {
        for (Laser l : level.lasers) {
            if (!l.lethal()) continue;
            Rectangle r = l.rect;
            if (!player.overlaps(r)) continue;
            float overlapX = Math.min(player.x + player.w - r.x, r.x + r.width - player.x);
            float overlapY = Math.min(player.y + player.h - r.y, r.y + r.height - player.y);
            if (overlapX <= overlapY) {
                if (player.centerX() < r.x + r.width * 0.5f) player.x -= overlapX;
                else player.x += overlapX;
                player.vx = 0f;
            } else {
                if (player.centerY() < r.y + r.height * 0.5f) player.y -= overlapY;
                else { player.y += overlapY; player.vy = 0f; }
            }
        }
    }

    public static boolean pitDeath(Body b) {
        return b.y < PIT_Y;
    }
}
