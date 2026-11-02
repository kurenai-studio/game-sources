package com.micro1.cookiesort;

import org.junit.jupiter.api.Test;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Headless logic tests for {@link CookieSortWorld} - no Gdx.* statics, no live window required. */
public class CookieSortWorldTest {

    private static int firstIndexOfType(CookieSortWorld world, CookieType type) {
        for (int i = 0; i < world.cookies.length; i++) {
            if (world.cookies[i].type == type) return i;
        }
        throw new AssertionError("no cookie of type " + type + " found");
    }

    /** All cookie indices of a given type, in deck order - used when a test needs several distinct
     * same-type cookies (a cookie already placed no longer hit-tests on the center plate, so reusing one
     * index across multiple drags is not valid). */
    private static List<Integer> indicesOfType(CookieSortWorld world, CookieType type) {
        List<Integer> indices = new ArrayList<Integer>();
        for (int i = 0; i < world.cookies.length; i++) {
            if (world.cookies[i].type == type) indices.add(i);
        }
        return indices;
    }

    @Test
    public void startsWithFortyMixedUnassignedCookies() {
        CookieSortWorld world = new CookieSortWorld(new Random(1));
        assertEquals(40, world.cookies.length);
        int light = 0, dark = 0;
        for (Cookie cookie : world.cookies) {
            if (cookie.type == CookieType.LIGHT) light++;
            else dark++;
            assertNull(cookie.placedOn);
        }
        assertTrue(light >= 1, "expected at least one light cookie");
        assertTrue(dark >= 1, "expected at least one dark cookie");
        assertEquals(40, light + dark);
        for (CornerPlate plate : world.corners) {
            assertFalse(plate.isAssigned());
            assertEquals(0, plate.placedCookieIds.size());
        }
        assertEquals(CookieSortWorld.COUNTDOWN_SECONDS, world.remainingSeconds, 0.001f);
        assertEquals(CookieSortWorld.State.PLAYING, world.state);
    }

    @Test
    public void firstCookieAssignsPlateAndCapsAtTwoPerType() {
        // Run across several seeds: the plate-assignment invariant (exactly 2 plates per type once all
        // four are assigned) must hold regardless of shuffle order, not just for one lucky seed.
        for (long seed = 0; seed < 25; seed++) {
            CookieSortWorld world = new CookieSortWorld(new Random(seed));
            List<Integer> lightIndices = indicesOfType(world, CookieType.LIGHT);
            List<Integer> darkIndices = indicesOfType(world, CookieType.DARK);
            assertTrue(lightIndices.size() >= 3, "seed " + seed + ": need >=3 light cookies for this scenario");
            assertTrue(darkIndices.size() >= 2, "seed " + seed + ": need >=2 dark cookies for this scenario");

            // Assign all four plates: light, light, dark, dark, using two DISTINCT light cookies (a
            // placed cookie no longer hit-tests on the center plate, so each drag needs its own cookie)
            // on two different unassigned plates, then two distinct dark cookies.
            dragTo(world, lightIndices.get(0), world.corners[0].cx, world.corners[0].cy);
            assertEquals(CookieType.LIGHT, world.corners[0].assignedType);
            dragTo(world, lightIndices.get(1), world.corners[1].cx, world.corners[1].cy);
            assertEquals(CookieType.LIGHT, world.corners[1].assignedType);

            // A third (distinct) light cookie dropped on the last unassigned plate must be REJECTED
            // (would break the 2-per-type split) even though that plate itself has never seen a cookie.
            int successfulBefore = world.metrics.successfulPlacements;
            int failedBefore = world.metrics.failedPlacements;
            dragTo(world, lightIndices.get(2), world.corners[2].cx, world.corners[2].cy);
            assertFalse(world.corners[2].isAssigned(), "seed " + seed + ": plate 2 must stay unassigned after a capped-type drop");
            assertEquals(successfulBefore, world.metrics.successfulPlacements);
            assertEquals(failedBefore + 1, world.metrics.failedPlacements);

            // A dark cookie on that same still-unassigned plate must succeed.
            dragTo(world, darkIndices.get(0), world.corners[2].cx, world.corners[2].cy);
            assertEquals(CookieType.DARK, world.corners[2].assignedType);
            dragTo(world, darkIndices.get(1), world.corners[3].cx, world.corners[3].cy);
            assertEquals(CookieType.DARK, world.corners[3].assignedType);

            int lightPlates = 0, darkPlates = 0;
            for (CornerPlate plate : world.corners) {
                if (plate.assignedType == CookieType.LIGHT) lightPlates++;
                else if (plate.assignedType == CookieType.DARK) darkPlates++;
            }
            assertEquals(2, lightPlates, "seed " + seed);
            assertEquals(2, darkPlates, "seed " + seed);
        }
    }

    @Test
    public void wrongTypeRejectedOnAssignedPlate() {
        CookieSortWorld world = new CookieSortWorld(new Random(2));
        int lightIdx = firstIndexOfType(world, CookieType.LIGHT);
        int darkIdx = firstIndexOfType(world, CookieType.DARK);
        CornerPlate plate = world.corners[0];
        dragTo(world, lightIdx, plate.cx, plate.cy); // assigns plate 0 to LIGHT

        int failedBefore = world.metrics.failedPlacements;
        int movedBefore = world.metrics.totalCookiesMoved;
        dragTo(world, darkIdx, plate.cx, plate.cy); // wrong type
        assertEquals(failedBefore + 1, world.metrics.failedPlacements);
        assertEquals(movedBefore + 1, world.metrics.totalCookiesMoved);
        assertNull(world.cookies[darkIdx].placedOn, "rejected cookie must not be marked placed");
        assertEquals(world.cookies[darkIdx].homeX, world.cookies[darkIdx].x, 0.001f, "rejected cookie returns home");
    }

    @Test
    public void releaseOutsideAnyPlateIsACancellationNotAFailure() {
        CookieSortWorld world = new CookieSortWorld(new Random(3));
        int idx = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookie = world.cookies[idx];

        int movedBefore = world.metrics.totalCookiesMoved;
        int cancelBefore = world.metrics.dragCancellations;
        world.beginDrag(cookie.homeX, cookie.homeY, 1000L);
        world.updateDrag(700f, 700f); // empty space, not over any corner plate
        world.endDrag(700f, 700f, 1500L);

        assertEquals(movedBefore, world.metrics.totalCookiesMoved, "a cancellation must not count as moved");
        assertEquals(cancelBefore + 1, world.metrics.dragCancellations);
        assertNull(cookie.placedOn);
        assertEquals(cookie.homeX, cookie.x, 0.001f);
    }

    @Test
    public void onlyOneDragActiveAtATime() {
        CookieSortWorld world = new CookieSortWorld(new Random(4));
        int first = firstIndexOfType(world, CookieType.LIGHT);
        Cookie firstCookie = world.cookies[first];
        boolean started = world.beginDrag(firstCookie.homeX, firstCookie.homeY, 0L);
        assertTrue(started);

        // Try to start a second drag on a different cookie while the first is still active.
        for (Cookie candidate : world.cookies) {
            if (candidate == firstCookie) continue;
            boolean secondStarted = world.beginDrag(candidate.homeX, candidate.homeY, 10L);
            assertFalse(secondStarted, "a second drag must not start while one is active");
            break;
        }
        assertTrue(world.isDragging());
        assertEquals(firstCookie, world.draggedCookie());
    }

    @Test
    public void winTriggersWhenAllCookiesValidlySorted() {
        CookieSortWorld world = new CookieSortWorld(new Random(5));
        sortEveryCookieCorrectly(world);
        assertEquals(CookieSortWorld.State.WON, world.state);
        assertTrue(world.consumeLogPending(), "a WIN transition must set logPending");
        assertFalse(world.consumeLogPending(), "logPending must only fire once");
    }

    @Test
    public void lossTriggersWhenTimerExpiresWithCookiesRemaining() {
        CookieSortWorld world = new CookieSortWorld(new Random(6));
        world.update(CookieSortWorld.COUNTDOWN_SECONDS + 1f);
        assertEquals(CookieSortWorld.State.LOST, world.state);
        assertEquals(0f, world.remainingSeconds, 0.001f);
        assertTrue(world.consumeLogPending());
        assertFalse(world.consumeLogPending());
    }

    @Test
    public void terminalStateFreezesFurtherInput() {
        CookieSortWorld world = new CookieSortWorld(new Random(7));
        world.update(CookieSortWorld.COUNTDOWN_SECONDS + 1f); // force LOST
        assertEquals(CookieSortWorld.State.LOST, world.state);

        int idx = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookie = world.cookies[idx];
        boolean started = world.beginDrag(cookie.homeX, cookie.homeY, 999L);
        assertFalse(started, "no drag should start once the game is over");
        assertFalse(world.isDragging());

        int movedBefore = world.metrics.totalCookiesMoved;
        world.endDrag(world.corners[0].cx, world.corners[0].cy, 1000L);
        assertEquals(movedBefore, world.metrics.totalCookiesMoved, "endDrag must no-op post-game");
    }

    @Test
    public void metricsAverageMovementTimeAndDragDistanceAccumulate() {
        CookieSortWorld world = new CookieSortWorld(new Random(8));
        int a = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookieA = world.cookies[a];
        world.beginDrag(cookieA.homeX, cookieA.homeY, 0L);
        world.updateDrag(cookieA.homeX + 30f, cookieA.homeY); // 30px
        world.updateDrag(cookieA.homeX + 30f, cookieA.homeY + 40f); // +40px (3-4-5 triangle style step)
        world.endDrag(world.corners[0].cx, world.corners[0].cy, 200L); // 200ms movement time

        assertEquals(1, world.metrics.totalCookiesMoved);
        assertEquals(200L, world.metrics.averageMovementTimeMs());
        float expectedFirstDistance = 70f + distance(
            cookieA.homeX + 30f, cookieA.homeY + 40f,
            world.corners[0].cx, world.corners[0].cy
        );
        assertEquals(expectedFirstDistance, world.metrics.totalDragDistancePx, 0.01f);

        int darkIdx = firstIndexOfType(world, CookieType.DARK);
        Cookie cookieB = world.cookies[darkIdx];
        // Second attempt targets a plate assigned to LIGHT (from the first drag above) with a DARK
        // cookie - a rejected attempt that still counts toward totalCookiesMoved/averageMovementTime.
        world.beginDrag(cookieB.homeX, cookieB.homeY, 1000L);
        world.endDrag(world.corners[0].cx, world.corners[0].cy, 1300L); // 300ms movement time

        assertEquals(2, world.metrics.totalCookiesMoved);
        assertEquals(1, world.metrics.successfulPlacements);
        assertEquals(1, world.metrics.failedPlacements);
        assertEquals((200L + 300L) / 2, world.metrics.averageMovementTimeMs());
    }

    @Test
    public void releasePointContributesToDragDistance() {
        CookieSortWorld world = new CookieSortWorld(new Random(12));
        int idx = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookie = world.cookies[idx];
        CornerPlate plate = world.corners[0];

        world.beginDrag(cookie.homeX, cookie.homeY, 100L);
        world.endDrag(plate.cx, plate.cy, 250L);

        assertEquals(1, world.metrics.totalCookiesMoved);
        assertEquals(
            distance(cookie.homeX, cookie.homeY, plate.cx, plate.cy),
            world.metrics.totalDragDistancePx,
            0.01f
        );
        assertEquals(plate.corner, cookie.placedOn);
    }

    @Test
    public void timerExpiryClearsActiveDragAndReturnsCookieHome() {
        CookieSortWorld world = new CookieSortWorld(new Random(13));
        int idx = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookie = world.cookies[idx];

        assertTrue(world.beginDrag(cookie.homeX, cookie.homeY, 0L));
        world.updateDrag(cookie.homeX + 100f, cookie.homeY + 50f);
        assertTrue(world.isDragging());

        world.update(CookieSortWorld.COUNTDOWN_SECONDS + 1f);

        assertEquals(CookieSortWorld.State.LOST, world.state);
        assertFalse(world.isDragging(), "timeout must not leave an uncleared active drag");
        assertNull(cookie.placedOn);
        assertEquals(cookie.homeX, cookie.x, 0.001f);
        assertEquals(cookie.homeY, cookie.y, 0.001f);
        assertEquals(0, world.metrics.totalCookiesMoved);
        assertEquals(0, world.metrics.dragCancellations);
    }

    @Test
    public void mostFrequentlyUsedCornerJoinsLabelsOnATie() {
        CookieSortWorld world = new CookieSortWorld(new Random(9));
        Corner a = Corner.TOP_LEFT;
        Corner b = Corner.BOTTOM_RIGHT;
        world.metrics.recordPlacementAttempt(a, true, 100L, 10f);
        world.metrics.recordPlacementAttempt(b, true, 100L, 10f);
        String label = world.metrics.mostFrequentlyUsedCorners();
        assertTrue(label.contains(a.label));
        assertTrue(label.contains(b.label));
    }

    @Test
    public void idleTimeAccumulatesBetweenActionsNotDuringThem() {
        CookieSortWorld world = new CookieSortWorld(new Random(10));
        int idx = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookie = world.cookies[idx];

        // reset() stamps lastActionEnd at "now" (real time); simulate an idle gap by beginning the
        // first drag well after construction using an explicit later timestamp far in the future so the
        // elapsed-since-reset gap (unknown/small) is negligible next to this deliberate 5s gap.
        long start = System.currentTimeMillis() + 5000L;
        world.beginDrag(cookie.homeX, cookie.homeY, start);
        world.endDrag(700f, 700f, start + 50L); // cancellation, 50ms "movement" (untracked)

        long idleAfterFirst = world.metrics.idleTimeMs;
        assertTrue(idleAfterFirst >= 4900L, "expected the ~5s pre-action gap to be counted as idle");

        // A second action starting only 10ms after the first ends (start+50 -> start+60) should add
        // exactly that 10ms gap, not the drag's own duration.
        world.beginDrag(cookie.homeX, cookie.homeY, start + 60L);
        world.endDrag(700f, 700f, start + 120L);
        assertEquals(idleAfterFirst + 10L, world.metrics.idleTimeMs, "only the inter-action gap should add idle time");
    }

    @Test
    public void logWriterFileNameMatchesTheReferenceFormatExactly() throws Exception {
        SimpleDateFormat parse = new SimpleDateFormat("dd-MM-yyyy-HH-mm-ss");
        Date sample = parse.parse("27-05-2026-11-45-01");
        assertEquals("27-05-2026-11-45-01-metrics.log", MetricsLogWriter.fileName(sample));
    }

    @Test
    public void logWriterBodyContainsAllEightLabeledMetrics() {
        Metrics metrics = new Metrics();
        metrics.recordPlacementAttempt(Corner.BOTTOM_LEFT, true, 200L, 700f);
        String body = MetricsLogWriter.body(metrics);
        String[] expectedLabels = {
            "total_cookies_moved:", "number_of_successful_placements:", "number_of_failed_placements:",
            "average_movement_time_per_cookie:", "total_drag_distance:", "most_frequently_used_corner_plates:",
            "idle_time_between_actions:", "number_of_drag_cancellations:"
        };
        for (String label : expectedLabels) {
            assertTrue(body.contains(label), "missing label: " + label);
        }
    }

    @Test
    public void placedCookieNoLongerHitTestsOnTheCenterPlate() {
        CookieSortWorld world = new CookieSortWorld(new Random(11));
        int idx = firstIndexOfType(world, CookieType.LIGHT);
        Cookie cookie = world.cookies[idx];
        float homeX = cookie.homeX;
        float homeY = cookie.homeY;
        assertEquals(idx, world.hitTestCenterCookie(homeX, homeY));

        dragTo(world, idx, world.corners[0].cx, world.corners[0].cy);
        assertEquals(world.corners[0].corner, cookie.placedOn);
        assertEquals(-1, world.hitTestCenterCookie(homeX, homeY), "a placed cookie must not hit-test at its old home slot");
    }

    /** Simulates a full realistic drag: press at the cookie's current position, move to (tx, ty), release. */
    private static void dragTo(CookieSortWorld world, int cookieId, float tx, float ty) {
        Cookie cookie = world.cookies[cookieId];
        long now = System.currentTimeMillis();
        boolean started = world.beginDrag(cookie.x, cookie.y, now);
        if (!started) return; // caller asserts on the resulting state, not on whether it started
        world.updateDrag(tx, ty);
        world.endDrag(tx, ty, now + 150L);
    }

    private static float distance(float x1, float y1, float x2, float y2) {
        float dx = x1 - x2;
        float dy = y1 - y2;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    /** Drives real beginDrag/updateDrag/endDrag calls until every cookie sits on a matching corner plate. */
    private static void sortEveryCookieCorrectly(CookieSortWorld world) {
        Corner[] lightCorners = {Corner.TOP_LEFT, Corner.TOP_RIGHT};
        Corner[] darkCorners = {Corner.BOTTOM_LEFT, Corner.BOTTOM_RIGHT};
        int lightTurn = 0, darkTurn = 0;
        for (int i = 0; i < world.cookies.length; i++) {
            if (world.state != CookieSortWorld.State.PLAYING) return;
            Cookie cookie = world.cookies[i];
            Corner target = (cookie.type == CookieType.LIGHT)
                ? lightCorners[(lightTurn++) % 2]
                : darkCorners[(darkTurn++) % 2];
            CornerPlate plate = world.corners[target.ordinal()];
            dragTo(world, i, plate.cx, plate.cy);
        }
    }
}
