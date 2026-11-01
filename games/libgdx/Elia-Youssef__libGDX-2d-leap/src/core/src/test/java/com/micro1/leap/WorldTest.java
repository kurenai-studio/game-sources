package com.micro1.leap;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.badlogic.gdx.math.Rectangle;
import org.junit.jupiter.api.Test;

/**
 * Headless logic tests for {@link World}. These exercise the behavioral rubric
 * items (movement speed + bounds, jump/gravity, grounded-only jump, top-only
 * landing, fall reset, camera follow + clamp, goal/win, replay reset, and a full
 * auto-played P1->P10 reachability proof) without needing a window or GL context.
 */
class WorldTest {

    private static final float DT = 1f / 60f;

    @Test
    void startState() {
        World w = new World();
        assertEquals(40f, w.player.x, 0.001f);
        assertEquals(80f, w.player.y, 0.001f);
        assertTrue(w.player.grounded);
        assertEquals(World.State.PLAYING, w.state);
        assertEquals(400f, w.cameraX, 0.001f);   // visible left edge = 0
    }

    @Test
    void standingIsStable() {
        World w = new World();
        for (int i = 0; i < 120; i++) w.update(DT, false, false, false);
        assertEquals(80f, w.player.y, 0.001f);
        assertTrue(w.player.grounded);
    }

    @Test
    void movesRightAtSpeed() {
        World w = new World();
        w.update(0.1f, false, true, false);      // 200 px/s * 0.1s = 20 px
        assertEquals(60f, w.player.x, 0.5f);
        assertEquals(80f, w.player.y, 0.001f);   // still grounded on Platform 1
    }

    @Test
    void clampsLeftBound() {
        World w = new World();
        for (int i = 0; i < 120; i++) w.update(DT, true, false, false);
        assertEquals(0f, w.player.x, 0.001f);
    }

    @Test
    void clampsRightBound() {
        World w = new World();
        w.player.x = 3160f;
        w.player.y = 400f;        // on Platform 10 top
        w.player.grounded = true;
        for (int i = 0; i < 60; i++) w.update(DT, false, true, false);
        assertEquals(World.MAX_PLAYER_X, w.player.x, 0.001f); // 3168
    }

    @Test
    void jumpUsesSpecVelocity() {
        World w = new World();
        w.update(DT, false, false, true);
        assertFalse(w.player.grounded);
        assertEquals(520f - 900f * DT, w.player.vy, 0.001f);
        assertTrue(w.player.y > 80f);
    }

    @Test
    void noDoubleJump() {
        World w = new World();
        w.update(DT, false, false, true);        // jump from ground
        float vyAfterJump = w.player.vy;
        w.update(DT, false, false, true);        // try to jump again mid-air
        assertTrue(w.player.vy < vyAfterJump);   // still falling, not reset to 520
        assertTrue(w.player.vy < 520f);
    }

    @Test
    void apexHeightMatchesPhysics() {
        World w = new World();
        w.update(DT, false, false, true);        // initiate jump
        float maxY = w.player.y;
        for (int i = 0; i < 200; i++) {
            w.update(DT, false, false, false);
            maxY = Math.max(maxY, w.player.y);
            if (w.player.grounded) break;
        }
        // apex height = v^2 / (2g) = 520^2 / 1800 = 150.2; from y=80 -> ~230.2
        assertEquals(230.2f, maxY, 6f);
    }

    @Test
    void landsOnTopFromAbove() {
        World w = new World();
        w.player.x = 100f;        // over Platform 1 (top y=80)
        w.player.y = 200f;
        w.player.vy = 0f;
        w.player.grounded = false;
        for (int i = 0; i < 300; i++) {
            w.update(DT, false, false, false);
            if (w.player.grounded) break;
        }
        assertTrue(w.player.grounded);
        assertEquals(80f, w.player.y, 0.001f);
        assertEquals(0f, w.player.vy, 0.001f);
    }

    @Test
    void passesThroughUnderside() {
        World w = new World();
        w.player.x = 850f;        // inside Platform 3 column (800..1000, top 160)
        w.player.y = 120f;        // below the top, moving up
        w.player.vy = 300f;
        w.player.grounded = false;
        w.update(DT, false, false, false);
        assertTrue(w.player.y > 120f);   // not blocked by the underside
        assertFalse(w.player.grounded);
    }

    @Test
    void fallBelowFieldResetsImmediately() {
        World w = new World();
        w.player.x = 1320f;       // inside the 1280..1380 pit
        w.player.y = 10f;
        w.player.vy = 0f;
        w.player.grounded = false;
        for (int i = 0; i < 120; i++) w.update(DT, false, false, false);
        assertEquals(40f, w.player.x, 0.001f);
        assertEquals(80f, w.player.y, 0.001f);
        assertEquals(400f, w.cameraX, 0.001f);
        assertEquals(World.State.PLAYING, w.state);
    }

    @Test
    void cameraFollowsAndClamps() {
        World w = new World();
        // Mid-level: camera follows the player center exactly.
        w.player.x = 1000f; w.player.y = 300f; w.player.vy = 0f;
        w.update(DT, false, false, false);
        assertEquals(1016f, w.cameraX, 0.001f);
        // Far right: clamps to 2800 (visible left edge 2400).
        w.player.x = 3160f; w.player.y = 400f; w.player.vy = 0f;
        w.update(DT, false, false, false);
        assertEquals(2800f, w.cameraX, 0.001f);
    }

    @Test
    void goalOverlapWins() {
        World w = new World();
        w.player.x = 3000f;       // exactly on the goal (3000,400,32,48)
        w.player.y = 400f;
        w.player.vy = 0f;
        w.update(DT, false, false, false);
        assertEquals(World.State.WON, w.state);
    }

    @Test
    void winFreezesInput() {
        World w = new World();
        w.state = World.State.WON;
        float x = w.player.x;
        float cam = w.cameraX;
        for (int i = 0; i < 60; i++) w.update(DT, false, true, true);
        assertEquals(x, w.player.x, 0.001f);
        assertEquals(cam, w.cameraX, 0.001f);
    }

    @Test
    void playAgainResets() {
        World w = new World();
        w.state = World.State.WON;
        w.player.x = 3000f; w.player.y = 400f;
        w.playAgain();
        assertEquals(World.State.PLAYING, w.state);
        assertEquals(40f, w.player.x, 0.001f);
        assertEquals(80f, w.player.y, 0.001f);
        assertEquals(400f, w.cameraX, 0.001f);
        assertEquals(3000f, w.level.goal.x, 0.001f);  // goal still present
        assertEquals(400f, w.level.goal.y, 0.001f);
    }

    @Test
    void routeIsCompletable() {
        World w = new World();
        boolean won = false;
        for (int i = 0; i < 60 * 60 && !won; i++) {   // up to 60 simulated seconds
            boolean[] act = decide(w);
            w.update(DT, act[0], act[1], act[2]);
            if (w.state == World.State.WON) won = true;
        }
        assertTrue(won, "auto-player should reach the goal using only run-right and grounded jumps");
    }

    // ---- auto-player used by routeIsCompletable ----

    // Policy: when standing on the platform that holds the goal, walk toward the
    // goal (no jump). Otherwise run right and jump just before the current
    // platform's right edge. Returns {left, right, jump}.
    private boolean[] decide(World w) {
        Rectangle cur = currentPlatform(w);
        if (cur != null) {
            boolean goalHere = w.level.goal.x >= cur.x && w.level.goal.x < cur.x + cur.width;
            if (goalHere) {
                if (w.player.x < w.level.goal.x - 1f) return new boolean[]{false, true, false};
                if (w.player.x > w.level.goal.x + 1f) return new boolean[]{true, false, false};
                return new boolean[]{false, false, false};
            }
            float rightEdge = cur.x + cur.width;
            boolean jump = w.player.x + World.PLAYER_W >= rightEdge - 2f;
            return new boolean[]{false, true, jump};
        }
        return new boolean[]{false, true, false};   // airborne: keep drifting right
    }

    private Rectangle currentPlatform(World w) {
        if (!w.player.grounded) return null;
        for (Rectangle p : w.level.platforms) {
            float top = p.y + p.height;
            boolean xOverlap = w.player.x + World.PLAYER_W > p.x && w.player.x < p.x + p.width;
            if (xOverlap && Math.abs(w.player.y - top) < 0.5f) return p;
        }
        return null;
    }
}
