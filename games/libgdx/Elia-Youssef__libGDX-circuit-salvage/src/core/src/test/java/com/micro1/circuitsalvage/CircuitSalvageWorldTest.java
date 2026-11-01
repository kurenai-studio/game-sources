package com.micro1.circuitsalvage;

import com.badlogic.gdx.math.Rectangle;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Headless logic tests for {@link CircuitSalvageWorld} - no Gdx.* statics, no live window
 * required. Every movement path below is chosen so it is safe from a spark hazard by distance
 * alone (player Y far enough from spark A's fixed row, or player X far enough from spark B's
 * fixed column) rather than by lucky timing, so the tests are not flaky.
 */
public class CircuitSalvageWorldTest {

    /** Fine-grained simulated stepping (240 steps/sec) so patrol bounces resolve realistically. */
    private static final float TEST_DT = 1f / 240f;

    private static void step(CircuitSalvageWorld world, float seconds,
                              boolean up, boolean down, boolean left, boolean right) {
        float elapsed = 0f;
        while (elapsed < seconds - 1e-6f) {
            float dt = Math.min(TEST_DT, seconds - elapsed);
            world.update(dt, up, down, left, right);
            elapsed += dt;
        }
    }

    @Test
    public void initialStateMatchesSpec() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        assertEquals(152f, world.getPlayerX(), 0.001f);
        assertEquals(72f, world.getPlayerY(), 0.001f);
        assertEquals(0, world.getBatteriesCollected());
        for (Battery battery : world.getBatteries()) {
            assertFalse(battery.isCollected());
        }
        assertTrue(world.getExit().isLocked());
        assertEquals(200f, world.getSparkA().getCenterX(), 0.001f);
        assertEquals(264f, world.getSparkA().getCenterY(), 0.001f);
        assertEquals(344f, world.getSparkB().getCenterX(), 0.001f);
        assertEquals(120f, world.getSparkB().getCenterY(), 0.001f);
        assertEquals(GameState.PLAYING, world.getState());
    }

    @Test
    public void movementNeverDiagonal_verticalWinsWhenBothPressed() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        float startX = world.getPlayerX();

        step(world, 0.1f, true, false, true, false); // up + left both held

        assertEquals(startX, world.getPlayerX(), 0.001f, "horizontal must not move while a vertical key is held");
        assertTrue(world.getPlayerY() > 72f, "vertical movement should have occurred");
    }

    @Test
    public void movementHorizontal_whenNoVerticalInput() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        float startY = world.getPlayerY();

        step(world, 0.1f, false, false, false, true); // right only

        assertEquals(startY, world.getPlayerY(), 0.001f);
        assertTrue(world.getPlayerX() > 152f);
    }

    @Test
    public void playerClampedAtLeftAndBottomEdges() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 1.0f, false, false, true, false); // already at the left edge
        assertEquals(MapConstants.MAP_LEFT + CircuitSalvageWorld.PLAYER_SIZE / 2f, world.getPlayerX(), 0.05f);

        step(world, 1.0f, false, true, false, false); // already at the bottom edge
        assertEquals(MapConstants.MAP_BOTTOM + CircuitSalvageWorld.PLAYER_SIZE / 2f, world.getPlayerY(), 0.05f);
    }

    @Test
    public void playerClampedAtRightAndTopEdges() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 3.0f, false, false, false, true); // right, across the whole map and beyond
        assertEquals(MapConstants.MAP_RIGHT - CircuitSalvageWorld.PLAYER_SIZE / 2f, world.getPlayerX(), 0.05f);

        step(world, 3.0f, true, false, false, false); // up, across the whole map and beyond
        assertEquals(MapConstants.MAP_TOP - CircuitSalvageWorld.PLAYER_SIZE / 2f, world.getPlayerY(), 0.05f);

        // Column 7 is always outside spark A's [200,440] x-range, so this climb cannot be hit
        // even though it passes the exit's tile row; the exit stays locked (0 batteries).
        assertEquals(GameState.PLAYING, world.getState());
    }

    @Test
    public void playerCanReachTopLeftCorner() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 3.0f, true, false, false, false);  // up, column 0 is always safe from spark A
        step(world, 3.0f, false, false, true, false);  // left, already at the left edge

        assertEquals(MapConstants.MAP_LEFT + CircuitSalvageWorld.PLAYER_SIZE / 2f, world.getPlayerX(), 0.05f);
        assertEquals(MapConstants.MAP_TOP - CircuitSalvageWorld.PLAYER_SIZE / 2f, world.getPlayerY(), 0.05f);
        assertEquals(GameState.PLAYING, world.getState());
    }

    @Test
    public void batteryTryCollect_onlySucceedsOnce() {
        Battery battery = new Battery(100f, 100f);
        Rectangle overlapping = new Rectangle(90f, 90f, 32f, 32f);

        assertTrue(battery.tryCollect(overlapping));
        assertTrue(battery.isCollected());
        assertFalse(battery.tryCollect(overlapping), "an already-collected battery must not be collected again");
    }

    @Test
    public void batteryCollection_incrementsOnceAndDoesNotDoubleCount() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 0.6f, false, false, false, true); // right 96px -> x=248 (row 0, always safe)
        step(world, 0.3f, true, false, false, false); // up 48px -> y=120, battery 1 tile
        assertEquals(1, world.getBatteriesCollected());
        assertTrue(world.getBatteries()[0].isCollected());

        step(world, 0.3f, true, false, false, false); // move further up, off the battery tile
        step(world, 0.3f, false, true, false, false); // back down onto the now-empty tile
        assertEquals(1, world.getBatteriesCollected(), "re-entering a collected battery's tile must not double count");
    }

    @Test
    public void enteringExit_beforeAllBatteriesCollected_doesNotWin() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 2.1f, false, false, false, true); // right 336px -> x=488 (column 7, always safe)
        step(world, 2.1f, true, false, false, false);  // up 336px -> y=408, the exit tile

        assertEquals(GameState.PLAYING, world.getState());
        assertEquals(0, world.getBatteriesCollected());
        assertTrue(world.getExit().isLocked());
    }

    @Test
    public void collectingAllThreeBatteries_unlocksExitThenWinsOnExitEntry() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        // Battery 1 (2,1) via row 0 (always safe from spark B) then straight up (always safe from spark A).
        step(world, 0.6f, false, false, false, true); // right 96px -> x=248, y=72
        step(world, 0.3f, true, false, false, false); // up 48px -> y=120 -> battery 1
        assertEquals(1, world.getBatteriesCollected());

        // Back to row 0, then across to column 6, then up to battery 2 (6,2).
        step(world, 0.3f, false, true, false, false); // down 48px -> y=72
        step(world, 1.2f, false, false, false, true); // right 192px -> x=440, y=72
        step(world, 0.6f, true, false, false, false); // up 96px -> y=168 -> battery 2
        assertEquals(2, world.getBatteriesCollected());
        assertTrue(world.getExit().isLocked());

        // Back to row 0, across to column 0, up column 0 (always safe from spark A) to row 6,
        // then a short right hop to battery 3 (1,6) - too short to reach spark B's column.
        step(world, 0.6f, false, true, false, false); // down 96px -> y=72
        step(world, 1.8f, false, false, true, false); // left 288px -> x=152, y=72
        step(world, 1.8f, true, false, false, false); // up 288px -> y=360, x=152
        step(world, 0.3f, false, false, false, true); // right 48px -> x=200 -> battery 3
        assertEquals(3, world.getBatteriesCollected());
        assertFalse(world.getExit().isLocked());
        assertEquals(GameState.PLAYING, world.getState());

        // Up to row 7 (always safe from spark B), then across to the exit (7,7).
        step(world, 0.3f, true, false, false, false); // up 48px -> y=408
        step(world, 1.8f, false, false, false, true); // right 288px -> x=488 -> exit tile

        assertEquals(GameState.WIN, world.getState());
    }

    @Test
    public void sparkBouncesExactlyAtBounds() {
        Spark spark = new Spark(SparkAxis.HORIZONTAL, 264f, 200f, 440f, 200f, 1);
        float min = spark.getCenterX();
        float max = spark.getCenterX();

        // 1500 steps at 1/240s = 6.25s, more than one full 5s round trip.
        for (int i = 0; i < 1500; i++) {
            spark.update(TEST_DT);
            float x = spark.getCenterX();
            assertTrue(x >= 200f - 0.01f && x <= 440f + 0.01f, "spark left its patrol range: " + x);
            min = Math.min(min, x);
            max = Math.max(max, x);
        }

        // Both endpoints must actually be reached (rubric: "reaches both endpoint tiles"), not just bounded.
        assertEquals(200f, min, 0.5f, "spark never reached its column-1 endpoint");
        assertEquals(440f, max, 0.5f, "spark never reached its column-6 endpoint");
    }

    @Test
    public void sparkA_neverLeavesPatrolRange() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        float min = world.getSparkA().getCenterX();
        float max = min;
        for (int i = 0; i < 1500; i++) {
            world.update(TEST_DT, false, false, false, false);
            float x = world.getSparkA().getCenterX();
            assertTrue(x >= 200f - 0.01f && x <= 440f + 0.01f, "spark A left its patrol range: " + x);
            assertEquals(264f, world.getSparkA().getCenterY(), 0.001f);
            min = Math.min(min, x);
            max = Math.max(max, x);
        }
        assertEquals(200f, min, 0.5f, "spark A never reached its column-1 endpoint");
        assertEquals(440f, max, 0.5f, "spark A never reached its column-6 endpoint");
    }

    @Test
    public void sparkB_neverLeavesPatrolRange() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        float min = world.getSparkB().getCenterY();
        float max = min;
        for (int i = 0; i < 1500; i++) {
            world.update(TEST_DT, false, false, false, false);
            float y = world.getSparkB().getCenterY();
            assertTrue(y >= 120f - 0.01f && y <= 360f + 0.01f, "spark B left its patrol range: " + y);
            assertEquals(344f, world.getSparkB().getCenterX(), 0.001f);
            min = Math.min(min, y);
            max = Math.max(max, y);
        }
        assertEquals(120f, min, 0.5f, "spark B never reached its row-1 endpoint");
        assertEquals(360f, max, 0.5f, "spark B never reached its row-6 endpoint");
    }

    @Test
    public void sparkAContact_triggersLoss() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 1.2f, true, false, false, false); // up to y=264 (spark A's row), x=152 stays clear of it
        step(world, 0.9f, false, false, false, true); // right to x=296 (on spark A's row, far from column 4)
        step(world, 6.0f, false, false, false, false); // hold still through a full spark A sweep

        assertEquals(GameState.LOSS, world.getState());
    }

    @Test
    public void sparkBContact_triggersLoss() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();

        step(world, 1.2f, false, false, false, true); // right to x=344 (spark B's column), y=72 stays clear of it
        step(world, 0.8f, true, false, false, false); // up to y=200 (off spark A's row, on spark B's column)
        step(world, 6.0f, false, false, false, false); // hold still through a full spark B sweep

        assertEquals(GameState.LOSS, world.getState());
    }

    @Test
    public void freezesEverything_afterLoss_untilRestart() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        step(world, 1.2f, true, false, false, false);
        step(world, 0.9f, false, false, false, true);
        step(world, 6.0f, false, false, false, false);
        assertEquals(GameState.LOSS, world.getState());

        float frozenX = world.getPlayerX();
        float frozenY = world.getPlayerY();
        float frozenSparkAX = world.getSparkA().getCenterX();
        float frozenSparkBY = world.getSparkB().getCenterY();

        step(world, 2.0f, true, true, true, true); // input + time must not move anything now

        assertEquals(frozenX, world.getPlayerX(), 0.001f);
        assertEquals(frozenY, world.getPlayerY(), 0.001f);
        assertEquals(frozenSparkAX, world.getSparkA().getCenterX(), 0.001f);
        assertEquals(frozenSparkBY, world.getSparkB().getCenterY(), 0.001f);

        world.restart();
        assertEquals(GameState.PLAYING, world.getState());
    }

    @Test
    public void freezesEverything_afterWin_untilRestart() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        step(world, 0.6f, false, false, false, true);
        step(world, 0.3f, true, false, false, false);
        step(world, 0.3f, false, true, false, false);
        step(world, 1.2f, false, false, false, true);
        step(world, 0.6f, true, false, false, false);
        step(world, 0.6f, false, true, false, false);
        step(world, 1.8f, false, false, true, false);
        step(world, 1.8f, true, false, false, false);
        step(world, 0.3f, false, false, false, true);
        step(world, 0.3f, true, false, false, false);
        step(world, 1.8f, false, false, false, true);
        assertEquals(GameState.WIN, world.getState());

        float frozenX = world.getPlayerX();
        float frozenY = world.getPlayerY();

        step(world, 2.0f, true, true, true, true);

        assertEquals(frozenX, world.getPlayerX(), 0.001f);
        assertEquals(frozenY, world.getPlayerY(), 0.001f);

        world.restart();
        assertEquals(GameState.PLAYING, world.getState());
    }

    @Test
    public void restart_resetsPlayerBatteriesSparksExitAndState() {
        CircuitSalvageWorld world = new CircuitSalvageWorld();
        step(world, 0.6f, false, false, false, true);
        step(world, 0.3f, true, false, false, false);
        assertEquals(1, world.getBatteriesCollected());

        world.restart();

        assertEquals(CircuitSalvageWorld.PLAYER_START_X, world.getPlayerX(), 0.001f);
        assertEquals(CircuitSalvageWorld.PLAYER_START_Y, world.getPlayerY(), 0.001f);
        assertEquals(0, world.getBatteriesCollected());
        for (Battery battery : world.getBatteries()) {
            assertFalse(battery.isCollected());
        }
        assertTrue(world.getExit().isLocked());
        assertEquals(200f, world.getSparkA().getCenterX(), 0.001f);
        assertEquals(264f, world.getSparkA().getCenterY(), 0.001f);
        assertEquals(344f, world.getSparkB().getCenterX(), 0.001f);
        assertEquals(120f, world.getSparkB().getCenterY(), 0.001f);
        assertEquals(GameState.PLAYING, world.getState());
    }
}
