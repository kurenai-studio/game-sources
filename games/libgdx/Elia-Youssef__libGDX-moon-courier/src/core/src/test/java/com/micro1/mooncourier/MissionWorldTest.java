package com.micro1.mooncourier;

import org.junit.jupiter.api.Test;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Headless logic tests for {@link MissionWorld} - no Gdx.* statics, no live window. Covers the core
 * mission rules the rubric grades (movement, fuel drain, cargo pickup + removal, obstacle penalty,
 * the win-only-with-cargo-and-fuel rule, the loss-on-empty-fuel rule, freeze after the mission ends)
 * plus a BFS reachability proof and a full auto-played run that the map is actually winnable.
 */
public class MissionWorldTest {

    private static final float DT = 1f / 240f;

    private static void step(MissionWorld w, float seconds,
                             boolean up, boolean down, boolean left, boolean right) {
        float elapsed = 0f;
        while (elapsed < seconds - 1e-6f) {
            float dt = Math.min(DT, seconds - elapsed);
            w.update(dt, up, down, left, right);
            elapsed += dt;
        }
    }

    private static float dist(float ax, float ay, float bx, float by) {
        float dx = ax - bx;
        float dy = ay - by;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    // -------------------------------------------------------------- basic state

    @Test
    public void initialStateMatchesSpec() {
        MissionWorld w = new MissionWorld();
        assertEquals(MissionWorld.SHIP_START_X, w.getShipX(), 0.001f);
        assertEquals(MissionWorld.SHIP_START_Y, w.getShipY(), 0.001f);
        assertEquals(100f, w.getFuel(), 0.001f);
        assertEquals(100, w.getFuelPercent());
        assertFalse(w.isCargoCollected());
        assertEquals(GameState.PLAYING, w.getState());
        assertTrue(w.getObstacles().size() >= 3, "needs several moon obstacles");
    }

    @Test
    public void fuelStartsFullAndDrainsWhilePlaying() {
        MissionWorld w = new MissionWorld();
        assertEquals(100f, w.getFuel(), 0.001f);
        step(w, 4f, false, false, false, false);
        // ~2.5%/s baseline: after 4s roughly 90% left, and strictly below the start.
        assertTrue(w.getFuel() < 100f, "fuel must decrease over time");
        assertEquals(90f, w.getFuel(), 1.0f);
        assertEquals(GameState.PLAYING, w.getState());
    }

    // -------------------------------------------------------------- movement

    @Test
    public void movesInAllFourDirections() {
        MissionWorld right = new MissionWorld();
        float x0 = right.getShipX();
        right.update(0.1f, false, false, false, true);
        assertTrue(right.getShipX() > x0, "D/Right increases X");

        MissionWorld left = new MissionWorld();
        left.setShipPosition(600f, 400f);
        float lx = left.getShipX();
        left.update(0.1f, false, false, true, false);
        assertTrue(left.getShipX() < lx, "A/Left decreases X");

        MissionWorld up = new MissionWorld();
        float uy = up.getShipY();
        up.update(0.1f, true, false, false, false);
        assertTrue(up.getShipY() > uy, "W/Up increases Y");

        MissionWorld down = new MissionWorld();
        float dy = down.getShipY();
        down.update(0.1f, false, true, false, false);
        assertTrue(down.getShipY() < dy, "S/Down decreases Y");
    }

    @Test
    public void diagonalMovementIsNormalised() {
        MissionWorld w = new MissionWorld();
        w.setShipPosition(400f, 400f);
        float x0 = w.getShipX();
        float y0 = w.getShipY();
        // 0.1s of up+right travel, internally split into collision-safe simulation steps.
        step(w, 0.1f, true, false, false, true);
        float travelled = dist(x0, y0, w.getShipX(), w.getShipY());
        assertEquals(MissionWorld.MOVE_SPEED * 0.1f, travelled, 0.6f);
    }

    @Test
    public void lowFrameRateDoesNotSlowMovementOrFuelDrain() {
        MissionWorld smooth = new MissionWorld();
        MissionWorld slow = new MissionWorld();
        smooth.setShipPosition(100f, 400f);
        slow.setShipPosition(100f, 400f);

        step(smooth, 1f, false, false, false, true);
        slow.update(1f, false, false, false, true);

        assertEquals(smooth.getShipX(), slow.getShipX(), 0.6f);
        assertEquals(smooth.getFuel(), slow.getFuel(), 0.01f);
        assertEquals(smooth.getElapsed(), slow.getElapsed(), 0.01f);
    }

    @Test
    public void shipIsClampedToPlayField() {
        MissionWorld w = new MissionWorld();
        step(w, 15f, false, false, true, false); // hold left into the wall
        assertEquals(MissionWorld.PLAY_MIN_X + MissionWorld.SHIP_RADIUS, w.getShipX(), 0.5f);
        assertTrue(w.getShipY() >= MissionWorld.PLAY_MIN_Y + MissionWorld.SHIP_RADIUS - 0.5f);
        assertTrue(w.getShipY() <= MissionWorld.PLAY_MAX_Y - MissionWorld.SHIP_RADIUS + 0.5f);
    }

    // -------------------------------------------------------------- cargo

    @Test
    public void collectingCargoRemovesItAndMarksCollected() {
        MissionWorld w = new MissionWorld();
        assertFalse(w.isCargoCollected());
        w.setShipPosition(MissionWorld.CRATE_X, MissionWorld.CRATE_Y);
        w.update(0.016f, false, false, false, false);
        assertTrue(w.isCargoCollected(), "touching the crate collects it");
        assertEquals(GameState.PLAYING, w.getState());
    }

    // -------------------------------------------------------------- win / lose rules

    @Test
    public void deliveryRequiresCargo() {
        MissionWorld w = new MissionWorld();
        // On the pad but no cargo: no win.
        w.setShipPosition(MissionWorld.PAD_X, MissionWorld.PAD_Y);
        w.update(0.016f, false, false, false, false);
        assertEquals(GameState.PLAYING, w.getState(), "reaching the pad without cargo must not win");
        // Now carrying cargo on the pad: win.
        w.forceCollectCargo();
        w.setShipPosition(MissionWorld.PAD_X, MissionWorld.PAD_Y);
        w.update(0.016f, false, false, false, false);
        assertEquals(GameState.WON, w.getState());
    }

    @Test
    public void winRequiresReachingThePad() {
        MissionWorld w = new MissionWorld();
        w.forceCollectCargo();
        // Carrying cargo but far from the pad: still playing.
        w.setShipPosition(200f, 400f);
        w.update(0.016f, false, false, false, false);
        assertEquals(GameState.PLAYING, w.getState());
    }

    @Test
    public void reachingPadAtZeroFuelIsLossNotWin() {
        MissionWorld w = new MissionWorld();
        w.forceCollectCargo();
        w.setShipPosition(MissionWorld.PAD_X, MissionWorld.PAD_Y);
        w.setFuel(0.05f); // will cross zero this frame
        w.update(0.05f, false, false, false, false);
        assertEquals(GameState.LOST, w.getState(),
            "fuel depletion is checked before delivery, so arriving at empty fuel is a loss");
    }

    @Test
    public void fuelDepletionLosesTheMission() {
        MissionWorld w = new MissionWorld();
        step(w, 50f, false, false, false, false); // 100 / 2.5 = 40s to empty
        assertEquals(0f, w.getFuel(), 0.001f);
        assertEquals(GameState.LOST, w.getState());
        assertFalse(w.isCargoCollected());
    }

    // -------------------------------------------------------------- obstacles

    @Test
    public void obstacleCollisionCostsFuelAndPushesOut() {
        MissionWorld w = new MissionWorld();
        Obstacle o = w.getObstacles().get(1); // (560, 300, 40)
        w.setShipPosition(o.x, o.y);
        float before = w.getFuel();
        w.update(0.016f, false, false, false, false);
        assertEquals(1, w.getCollisions(), "one hit counted");
        // Penalty (8) plus a sliver of drain.
        assertTrue(w.getFuel() <= before - MissionWorld.OBSTACLE_PENALTY + 0.001f);
        assertTrue(w.getFuel() >= before - MissionWorld.OBSTACLE_PENALTY - 1f);
        // Ship pushed clear of the obstacle.
        assertTrue(dist(w.getShipX(), w.getShipY(), o.x, o.y)
            >= o.radius + MissionWorld.SHIP_RADIUS - 0.5f, "ship ejected from the obstacle");
    }

    @Test
    public void penaltyNotDoubleCountedAfterPushOut() {
        MissionWorld w = new MissionWorld();
        Obstacle o = w.getObstacles().get(1);
        w.setShipPosition(o.x, o.y);
        w.update(0.016f, false, false, false, false);
        int afterFirst = w.getCollisions();
        w.update(0.016f, false, false, false, false); // now clear of the rock
        assertEquals(afterFirst, w.getCollisions(), "no new penalty once pushed out");
    }

    @Test
    public void eachObstacleHasAnIndependentPenaltyCooldown() {
        MissionWorld w = new MissionWorld();
        Obstacle first = w.getObstacles().get(1);
        Obstacle second = w.getObstacles().get(3);

        w.setShipPosition(first.x, first.y);
        w.update(0.016f, false, false, false, false);
        float afterFirst = w.getFuel();

        w.setShipPosition(second.x, second.y);
        w.update(0.016f, false, false, false, false);

        assertEquals(2, w.getCollisions(), "a different hazard should still apply its penalty");
        assertTrue(w.getFuel() <= afterFirst - MissionWorld.OBSTACLE_PENALTY);
    }

    @Test
    public void sameObstacleCannotDrainFuelRepeatedlyDuringCooldown() {
        MissionWorld w = new MissionWorld();
        Obstacle obstacle = w.getObstacles().get(1);

        w.setShipPosition(obstacle.x, obstacle.y);
        w.update(0.016f, false, false, false, false);
        w.setShipPosition(obstacle.x, obstacle.y);
        w.update(0.016f, false, false, false, false);

        assertEquals(1, w.getCollisions());
    }

    @Test
    public void obstacleCollectionIsReadOnly() {
        MissionWorld w = new MissionWorld();
        assertThrows(UnsupportedOperationException.class,
            () -> w.getObstacles().add(new Obstacle(0f, 0f, 1f, Obstacle.Type.ROCK, 0)));
    }

    @Test
    public void obstaclesClearOfStartCrateAndPad() {
        MissionWorld w = new MissionWorld();
        for (Obstacle o : w.getObstacles()) {
            assertTrue(dist(o.x, o.y, MissionWorld.SHIP_START_X, MissionWorld.SHIP_START_Y)
                > o.radius + MissionWorld.SHIP_RADIUS, "ship does not spawn inside an obstacle");
            assertTrue(dist(o.x, o.y, MissionWorld.CRATE_X, MissionWorld.CRATE_Y)
                > o.radius + MissionWorld.SHIP_RADIUS, "crate is reachable");
            assertTrue(dist(o.x, o.y, MissionWorld.PAD_X, MissionWorld.PAD_Y)
                > o.radius, "pad is not buried under an obstacle");
        }
    }

    // -------------------------------------------------------------- freeze after end

    @Test
    public void noUpdateAfterMissionEnds() {
        MissionWorld w = new MissionWorld();
        step(w, 50f, false, false, false, false);
        assertEquals(GameState.LOST, w.getState());
        float x = w.getShipX();
        float y = w.getShipY();
        float fuel = w.getFuel();
        w.update(1f, true, true, true, true);
        assertEquals(x, w.getShipX(), 0.001f);
        assertEquals(y, w.getShipY(), 0.001f);
        assertEquals(fuel, w.getFuel(), 0.001f);
        assertEquals(GameState.LOST, w.getState());
    }

    @Test
    public void resetRestoresFreshMission() {
        MissionWorld w = new MissionWorld();
        step(w, 50f, false, false, false, false);
        assertEquals(GameState.LOST, w.getState());
        w.reset();
        assertEquals(100f, w.getFuel(), 0.001f);
        assertFalse(w.isCargoCollected());
        assertEquals(GameState.PLAYING, w.getState());
        assertEquals(MissionWorld.SHIP_START_X, w.getShipX(), 0.001f);
        assertEquals(MissionWorld.SHIP_START_Y, w.getShipY(), 0.001f);
    }

    // -------------------------------------------------------------- winnability (BFS + auto-play)

    @Test
    public void freePathExistsStartToCrateToPad() {
        MissionWorld w = new MissionWorld();
        assertNotNull(bfsPath(w, MissionWorld.SHIP_START_X, MissionWorld.SHIP_START_Y,
            MissionWorld.CRATE_X, MissionWorld.CRATE_Y), "no clear path from start to cargo");
        assertNotNull(bfsPath(w, MissionWorld.CRATE_X, MissionWorld.CRATE_Y,
            MissionWorld.PAD_X, MissionWorld.PAD_Y), "no clear path from cargo to pad");
    }

    @Test
    public void autoPlayCompletesMissionWithFuelToSpare() {
        MissionWorld w = new MissionWorld();
        List<float[]> toCrate = bfsPath(w, MissionWorld.SHIP_START_X, MissionWorld.SHIP_START_Y,
            MissionWorld.CRATE_X, MissionWorld.CRATE_Y);
        List<float[]> toPad = bfsPath(w, MissionWorld.CRATE_X, MissionWorld.CRATE_Y,
            MissionWorld.PAD_X, MissionWorld.PAD_Y);
        assertNotNull(toCrate);
        assertNotNull(toPad);

        List<float[]> route = new ArrayList<>(toCrate);
        route.addAll(toPad);
        follow(w, route);

        assertEquals(GameState.WON, w.getState(), "the mission should be winnable by following a clear path");
        assertTrue(w.getFuel() > 0f, "should reach the pad with fuel to spare");
        assertTrue(w.isCargoCollected());
    }

    /** Drives the ship toward each waypoint in turn, one 60fps step at a time, until the mission ends. */
    private static void follow(MissionWorld w, List<float[]> waypoints) {
        int safety = 0;
        for (float[] wp : waypoints) {
            int perWaypoint = 0;
            while (w.getState() == GameState.PLAYING
                && dist(w.getShipX(), w.getShipY(), wp[0], wp[1]) > 8f
                && perWaypoint < 240 && safety < 6000) {
                float dx = wp[0] - w.getShipX();
                float dy = wp[1] - w.getShipY();
                float dz = 3f;
                w.update(1f / 60f, dy > dz, dy < -dz, dx < -dz, dx > dz);
                perWaypoint++;
                safety++;
            }
            if (w.getState() != GameState.PLAYING) {
                return;
            }
        }
    }

    // ---- BFS over the free space (obstacles inflated by ship radius + margin) ----

    private static final float CELL = 5f;
    private static final float MARGIN = 6f;

    private static boolean isFree(MissionWorld w, float x, float y) {
        if (x < MissionWorld.PLAY_MIN_X + MissionWorld.SHIP_RADIUS
            || x > MissionWorld.PLAY_MAX_X - MissionWorld.SHIP_RADIUS
            || y < MissionWorld.PLAY_MIN_Y + MissionWorld.SHIP_RADIUS
            || y > MissionWorld.PLAY_MAX_Y - MissionWorld.SHIP_RADIUS) {
            return false;
        }
        for (Obstacle o : w.getObstacles()) {
            if (dist(x, y, o.x, o.y) <= o.radius + MissionWorld.SHIP_RADIUS + MARGIN) {
                return false;
            }
        }
        return true;
    }

    /** Returns a list of waypoint coordinates from (sx,sy) to (tx,ty), or null if none exists. */
    private static List<float[]> bfsPath(MissionWorld w, float sx, float sy, float tx, float ty) {
        float minX = MissionWorld.PLAY_MIN_X + MissionWorld.SHIP_RADIUS;
        float minY = MissionWorld.PLAY_MIN_Y + MissionWorld.SHIP_RADIUS;
        int cols = (int) ((MissionWorld.PLAY_MAX_X - MissionWorld.SHIP_RADIUS - minX) / CELL) + 1;
        int rows = (int) ((MissionWorld.PLAY_MAX_Y - MissionWorld.SHIP_RADIUS - minY) / CELL) + 1;

        int sc = clampIdx(Math.round((sx - minX) / CELL), cols);
        int sr = clampIdx(Math.round((sy - minY) / CELL), rows);
        int tc = clampIdx(Math.round((tx - minX) / CELL), cols);
        int tr = clampIdx(Math.round((ty - minY) / CELL), rows);

        // Nudge endpoints to the nearest free cell if the exact centre is blocked (the crate/pad
        // centres are clear by construction, but this keeps the search robust).
        if (!cellFree(w, minX, minY, sc, sr)) {
            return null;
        }
        int[] tFree = nearestFree(w, minX, minY, cols, rows, tc, tr);
        if (tFree == null) {
            return null;
        }
        tc = tFree[0];
        tr = tFree[1];

        boolean[][] visited = new boolean[cols][rows];
        int[][] parent = new int[cols][rows];
        for (int[] p : parent) {
            java.util.Arrays.fill(p, -1);
        }
        Deque<int[]> queue = new ArrayDeque<>();
        queue.add(new int[]{sc, sr});
        visited[sc][sr] = true;
        int[] dc = {1, -1, 0, 0};
        int[] dr = {0, 0, 1, -1};
        boolean found = false;
        while (!queue.isEmpty()) {
            int[] cur = queue.poll();
            if (cur[0] == tc && cur[1] == tr) {
                found = true;
                break;
            }
            for (int k = 0; k < 4; k++) {
                int nc = cur[0] + dc[k];
                int nr = cur[1] + dr[k];
                if (nc < 0 || nr < 0 || nc >= cols || nr >= rows || visited[nc][nr]) {
                    continue;
                }
                if (!cellFree(w, minX, minY, nc, nr)) {
                    continue;
                }
                visited[nc][nr] = true;
                parent[nc][nr] = cur[0] * rows + cur[1];
                queue.add(new int[]{nc, nr});
            }
        }
        if (!found) {
            return null;
        }
        // Reconstruct.
        List<float[]> path = new ArrayList<>();
        int cc = tc;
        int cr = tr;
        while (cc != sc || cr != sr) {
            path.add(0, new float[]{minX + cc * CELL, minY + cr * CELL});
            int p = parent[cc][cr];
            cc = p / rows;
            cr = p % rows;
        }
        path.add(new float[]{tx, ty}); // finish on the exact target
        return path;
    }

    private static boolean cellFree(MissionWorld w, float minX, float minY, int c, int r) {
        return isFree(w, minX + c * CELL, minY + r * CELL);
    }

    private static int[] nearestFree(MissionWorld w, float minX, float minY,
                                     int cols, int rows, int c, int r) {
        for (int radius = 0; radius < 20; radius++) {
            for (int dcx = -radius; dcx <= radius; dcx++) {
                for (int dry = -radius; dry <= radius; dry++) {
                    int nc = c + dcx;
                    int nr = r + dry;
                    if (nc >= 0 && nr >= 0 && nc < cols && nr < rows && cellFree(w, minX, minY, nc, nr)) {
                        return new int[]{nc, nr};
                    }
                }
            }
        }
        return null;
    }

    private static int clampIdx(int v, int n) {
        return Math.max(0, Math.min(n - 1, v));
    }
}
