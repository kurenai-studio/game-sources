package com.micro1.minecart;

import com.badlogic.gdx.math.RandomXS128;
import com.badlogic.gdx.utils.Array;

/**
 * All railway-management simulation and game-state rules, with no libGDX graphics/input
 * dependency (only pure math + collection types), so it can be exercised headlessly.
 * {@code GameplayScreen} is a thin render/input shell over this.
 *
 * Coordinate space: top-left origin, x right, y down (matching the prompt exactly). All timing
 * is delta-time driven. The simulation splits into small package-visible steps
 * (advanceDifficulty / advanceSpawning / moveAndResolveCarts / checkCollisions) so each rule
 * can be unit-tested in isolation.
 */
public class MineCartWorld {

    public enum State { PLAYING, WON, LOST }

    // Layout (top-left origin).
    public static final float WIDTH = 1280f;
    public static final float HEIGHT = 720f;
    public static final int UPPER = 0;
    public static final int MIDDLE = 1;
    public static final int LOWER = 2;
    public static final float[] TRACK_Y = {180f, 360f, 540f};
    public static final float JUNCTION_X = 620f; // junction centre (switch line)
    public static final float CAVE_X = 1100f;    // cave left edge (delivery line)
    public static final float CART_W = 80f;
    public static final float CART_H = 40f;
    public static final float SPAWN_X = -80f;

    // Tuning.
    public static final float BASE_SPEED = 180f;
    public static final float SPEED_STEP = 10f;
    public static final float BASE_INTERVAL = 3f;
    public static final float INTERVAL_STEP = 0.4f;
    public static final float MIN_INTERVAL = 1.5f;
    public static final float DIFFICULTY_PERIOD = 25f;
    public static final int MAX_CARTS = 3;
    public static final int GOLD_PER_DELIVERY = 25;
    public static final int WIN_GOLD = 50;

    private final RandomXS128 rng;
    private final Array<Cart> carts = new Array<Cart>();

    private int selectedRoute;
    private float survivalTime;
    private float spawnTimer;
    private float difficultyTimer;
    private float cartSpeed;
    private float spawnInterval;
    private int gold;
    private State state;

    public MineCartWorld() {
        this(new RandomXS128());
    }

    /** Seeded constructor for deterministic tests. */
    public MineCartWorld(long seed) {
        this(new RandomXS128(seed));
    }

    private MineCartWorld(RandomXS128 rng) {
        this.rng = rng;
        reset();
    }

    /** Full reset to the initial state; a fresh session behaves exactly like a first launch. */
    public void reset() {
        carts.clear();
        selectedRoute = MIDDLE;
        survivalTime = 0f;
        difficultyTimer = 0f;
        cartSpeed = BASE_SPEED;
        spawnInterval = BASE_INTERVAL;
        gold = 0;
        state = State.PLAYING;
        spawnTimer = BASE_INTERVAL; // first cart enters right away
    }

    /** Route selection. Ignored on end states (gameplay input is frozen once won/lost). */
    public void setRoute(int route) {
        if (state == State.PLAYING) {
            selectedRoute = route;
        }
    }

    /** Advance one frame of simulation by {@code dt} seconds. Frozen on end states. */
    public void update(float dt) {
        if (state != State.PLAYING) {
            return;
        }
        survivalTime += dt;
        advanceDifficulty(dt);
        advanceSpawning(dt);
        moveAndResolveCarts(dt);
        if (gold >= WIN_GOLD) {
            state = State.WON;
            return;
        }
        checkCollisions();
    }

    /** Every 25 s: cart speed +10 px/s, spawn interval -0.4 s down to a 1.5 s floor. */
    void advanceDifficulty(float dt) {
        difficultyTimer += dt;
        while (difficultyTimer >= DIFFICULTY_PERIOD) {
            difficultyTimer -= DIFFICULTY_PERIOD;
            cartSpeed += SPEED_STEP;
            spawnInterval = Math.max(MIN_INTERVAL, spawnInterval - INTERVAL_STEP);
        }
    }

    /** Spawn a cart every {@code spawnInterval} seconds, never exceeding three at once. */
    void advanceSpawning(float dt) {
        spawnTimer += dt;
        if (spawnTimer >= spawnInterval) {
            if (carts.size < MAX_CARTS) {
                carts.add(new Cart(SPAWN_X, TRACK_Y[MIDDLE] - CART_H / 2f, rng.nextInt(3)));
                spawnTimer -= spawnInterval;
            } else {
                spawnTimer = spawnInterval; // hold at the threshold until a slot frees
            }
        }
    }

    /** Move carts right, switch them at the junction, and resolve cave arrivals. */
    void moveAndResolveCarts(float dt) {
        for (int i = carts.size - 1; i >= 0; i--) {
            Cart c = carts.get(i);
            c.x += cartSpeed * dt;

            if (!c.switched && c.centerX() >= JUNCTION_X) {
                c.switched = true;
                c.assignedTrack = selectedRoute;
                c.y = TRACK_Y[selectedRoute] - CART_H / 2f;
            }

            if (c.x + CART_W >= CAVE_X) {
                int track = c.switched ? c.assignedTrack : MIDDLE;
                if (track == c.destination) {
                    gold += GOLD_PER_DELIVERY;
                    carts.removeIndex(i);
                } else {
                    state = State.LOST;
                    return;
                }
            }
        }
    }

    /** Any AABB overlap between two cart rectangles crashes both and loses immediately. */
    void checkCollisions() {
        for (int i = 0; i < carts.size; i++) {
            for (int j = i + 1; j < carts.size; j++) {
                if (carts.get(i).bounds().overlaps(carts.get(j).bounds())) {
                    state = State.LOST;
                    return;
                }
            }
        }
    }

    // Read-only views for the render layer / tests.
    public Array<Cart> getCarts() {
        return carts;
    }

    public int getSelectedRoute() {
        return selectedRoute;
    }

    public int getGold() {
        return gold;
    }

    public int getSurvivalSeconds() {
        return (int) survivalTime;
    }

    public float getCartSpeed() {
        return cartSpeed;
    }

    public float getSpawnInterval() {
        return spawnInterval;
    }

    public State getState() {
        return state;
    }
}
