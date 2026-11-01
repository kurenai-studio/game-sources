package com.micro1.circuitsalvage;

import com.badlogic.gdx.math.Rectangle;

/**
 * GL-free game logic: player position, batteries, sparks, the exit, and the PLAYING/WIN/LOSS
 * state machine. Contains no libGDX graphics/audio/input imports beyond {@link Rectangle}, so it
 * runs under plain JUnit with no GL context.
 */
public final class CircuitSalvageWorld {

    public static final float PLAYER_SIZE = 32f;
    public static final float PLAYER_SPEED = 160f;

    public static final float PLAYER_START_X = MapConstants.tileCenterX(0);
    public static final float PLAYER_START_Y = MapConstants.tileCenterY(0);

    private static final float MIN_PLAYER_X = MapConstants.MAP_LEFT + PLAYER_SIZE / 2f;
    private static final float MAX_PLAYER_X = MapConstants.MAP_RIGHT - PLAYER_SIZE / 2f;
    private static final float MIN_PLAYER_Y = MapConstants.MAP_BOTTOM + PLAYER_SIZE / 2f;
    private static final float MAX_PLAYER_Y = MapConstants.MAP_TOP - PLAYER_SIZE / 2f;

    private float playerX;
    private float playerY;
    private final Rectangle playerBounds = new Rectangle(0, 0, PLAYER_SIZE, PLAYER_SIZE);

    private final Battery[] batteries;
    private final Spark sparkA;
    private final Spark sparkB;
    private final ExitDoor exit;

    private int batteriesCollected;
    private GameState state;

    public CircuitSalvageWorld() {
        batteries = new Battery[] {
            new Battery(MapConstants.tileCenterX(2), MapConstants.tileCenterY(1)),
            new Battery(MapConstants.tileCenterX(6), MapConstants.tileCenterY(2)),
            new Battery(MapConstants.tileCenterX(1), MapConstants.tileCenterY(6))
        };

        // Spark A: patrols row 4, columns 1-6, starting at (1,4) moving toward column 6.
        sparkA = new Spark(
            SparkAxis.HORIZONTAL,
            MapConstants.tileCenterY(4),
            MapConstants.tileCenterX(1),
            MapConstants.tileCenterX(6),
            MapConstants.tileCenterX(1),
            1
        );

        // Spark B: patrols column 4, rows 1-6, starting at (4,1) moving toward row 6.
        sparkB = new Spark(
            SparkAxis.VERTICAL,
            MapConstants.tileCenterX(4),
            MapConstants.tileCenterY(1),
            MapConstants.tileCenterY(6),
            MapConstants.tileCenterY(1),
            1
        );

        exit = new ExitDoor(MapConstants.tileCenterX(7), MapConstants.tileCenterY(7));

        restart();
    }

    /**
     * Advances the simulation one frame. A complete no-op while {@code state != PLAYING}, so
     * player and hazard movement freeze after a win or a loss until {@link #restart()}.
     */
    public void update(float delta, boolean up, boolean down, boolean left, boolean right) {
        if (state != GameState.PLAYING) {
            return;
        }

        movePlayer(delta, up, down, left, right);
        sparkA.update(delta);
        sparkB.update(delta);
        updatePlayerBounds();

        checkBatteryPickups();

        if (sparkA.overlaps(playerBounds) || sparkB.overlaps(playerBounds)) {
            state = GameState.LOSS;
            return;
        }

        if (batteriesCollected >= 3 && exit.overlaps(playerBounds)) {
            state = GameState.WIN;
        }
    }

    private void movePlayer(float delta, boolean up, boolean down, boolean left, boolean right) {
        int dy = (up ? 1 : 0) - (down ? 1 : 0);
        int dx = (right ? 1 : 0) - (left ? 1 : 0);

        // Vertical takes priority when both a vertical and horizontal key are held, so the player
        // never moves on both axes in the same frame (never diagonally), by construction.
        if (dy != 0) {
            playerY += dy * PLAYER_SPEED * delta;
        } else if (dx != 0) {
            playerX += dx * PLAYER_SPEED * delta;
        }

        if (playerX < MIN_PLAYER_X) {
            playerX = MIN_PLAYER_X;
        } else if (playerX > MAX_PLAYER_X) {
            playerX = MAX_PLAYER_X;
        }
        if (playerY < MIN_PLAYER_Y) {
            playerY = MIN_PLAYER_Y;
        } else if (playerY > MAX_PLAYER_Y) {
            playerY = MAX_PLAYER_Y;
        }
    }

    private void updatePlayerBounds() {
        playerBounds.set(playerX - PLAYER_SIZE / 2f, playerY - PLAYER_SIZE / 2f, PLAYER_SIZE, PLAYER_SIZE);
    }

    private void checkBatteryPickups() {
        for (Battery battery : batteries) {
            if (battery.tryCollect(playerBounds)) {
                batteriesCollected++;
            }
        }
        if (batteriesCollected >= 3) {
            exit.setLocked(false);
        }
    }

    /**
     * QA-only: forces the round into a named scenario for offscreen screenshot capture. Never
     * invoked during normal play (only reachable via the desktop launcher's {@code --scenario}
     * argument, which real gameplay never passes).
     */
    public void forceScenarioForQA(String scenario) {
        if (scenario == null) {
            return;
        }
        switch (scenario) {
            case "battery":
                batteries[0].tryCollect(batteries[0].getBounds());
                batteriesCollected = 1;
                break;
            case "allCollected":
            case "win":
                for (Battery battery : batteries) {
                    battery.tryCollect(battery.getBounds());
                }
                batteriesCollected = 3;
                exit.setLocked(false);
                if ("win".equals(scenario)) {
                    state = GameState.WIN;
                }
                break;
            case "loss":
                state = GameState.LOSS;
                break;
            default:
                break;
        }
    }

    /** Resets the player, all batteries, both sparks, the exit, and the state to their initial values. */
    public void restart() {
        playerX = PLAYER_START_X;
        playerY = PLAYER_START_Y;
        updatePlayerBounds();

        for (Battery battery : batteries) {
            battery.reset();
        }
        sparkA.reset();
        sparkB.reset();
        exit.reset();

        batteriesCollected = 0;
        state = GameState.PLAYING;
    }

    // --- Read-only accessors for the render layer and tests ---

    public float getPlayerX() {
        return playerX;
    }

    public float getPlayerY() {
        return playerY;
    }

    public Rectangle getPlayerBounds() {
        return playerBounds;
    }

    public Battery[] getBatteries() {
        return batteries;
    }

    public Spark getSparkA() {
        return sparkA;
    }

    public Spark getSparkB() {
        return sparkB;
    }

    public ExitDoor getExit() {
        return exit;
    }

    public int getBatteriesCollected() {
        return batteriesCollected;
    }

    public GameState getState() {
        return state;
    }
}
