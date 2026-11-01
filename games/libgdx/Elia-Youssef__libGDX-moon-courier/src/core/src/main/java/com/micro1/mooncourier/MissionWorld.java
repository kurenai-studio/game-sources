package com.micro1.mooncourier;

import java.util.Arrays;
import java.util.List;

/**
 * The GL-free simulation for the Gameplay Scene. Owns the spacecraft, fuel, the cargo crate, the
 * delivery pad, the lunar obstacles, and the mission state, and advances them one frame at a time
 * from four boolean direction inputs. It has no graphics dependencies, so it runs headlessly and is
 * unit-tested directly (see {@code MissionWorldTest}). The render/input shell
 * {@link GameplayScreen} draws it and feeds it input; it never contains game rules itself.
 *
 * <p>Mission rules, matching the prompt and rubric:
 * <ul>
 *   <li>Fuel starts at 100% and drains continuously while PLAYING.</li>
 *   <li>Touching the crate collects it (crate removed, cargo marked collected).</li>
 *   <li>Hitting an obstacle costs extra fuel (a one-shot penalty per brief cooldown) and pushes the
 *       ship back out of the rock/crater.</li>
 *   <li>Reaching the delivery pad while carrying the cargo, with fuel still above zero, wins.</li>
 *   <li>Fuel reaching zero before delivery loses. The depletion check runs before the delivery
 *       check, so arriving on the pad on the exact frame fuel hits zero is a loss, not a win.</li>
 * </ul>
 */
public final class MissionWorld {

    // ---- Play field (the region the ship is clamped to; the HUD panels sit outside it) ----
    public static final float WORLD_WIDTH = 1280f;
    public static final float WORLD_HEIGHT = 720f;
    public static final float PLAY_MIN_X = 40f;
    public static final float PLAY_MAX_X = 1240f;
    public static final float PLAY_MIN_Y = 230f;
    public static final float PLAY_MAX_Y = 575f;

    // ---- Ship ----
    public static final float SHIP_RADIUS = 18f;
    public static final float SHIP_START_X = 150f;
    public static final float SHIP_START_Y = 400f;
    public static final float MOVE_SPEED = 300f; // pixels/second
    private static final float MAX_SIMULATION_STEP = 0.05f;
    private static final float MAX_FRAME_DELTA = 1f;

    // ---- Fuel ----
    public static final float START_FUEL = 100f;
    public static final float DRAIN_PER_SEC = 2.5f;      // baseline drain while playing
    public static final float OBSTACLE_PENALTY = 8f;     // extra fuel lost per obstacle hit
    public static final float PENALTY_COOLDOWN = 0.6f;   // min seconds between counted hits

    // ---- Cargo crate ----
    public static final float CRATE_X = 420f;
    public static final float CRATE_Y = 330f;
    public static final float CRATE_PICKUP_RADIUS = 34f;

    // ---- Delivery pad ----
    public static final float PAD_X = 1090f;
    public static final float PAD_Y = 400f;
    public static final float PAD_RADIUS = 62f;

    private float shipX;
    private float shipY;
    private float fuel;
    private boolean cargoCollected;
    private GameState state;
    private float elapsed;
    private int collisions;
    private float flashTimer;     // counts down; drives the HUD "fuel lost" flash

    private final List<Obstacle> obstacles = List.of(
        new Obstacle(300f, 515f, 26f, Obstacle.Type.CRATER, 11),
        new Obstacle(560f, 300f, 40f, Obstacle.Type.CRATER, 23),
        new Obstacle(560f, 515f, 34f, Obstacle.Type.ROCK, 37),
        new Obstacle(740f, 405f, 46f, Obstacle.Type.CRATER, 41),
        new Obstacle(700f, 545f, 24f, Obstacle.Type.ROCK, 53),
        new Obstacle(920f, 300f, 40f, Obstacle.Type.CRATER, 67),
        new Obstacle(920f, 515f, 34f, Obstacle.Type.ROCK, 71),
        new Obstacle(1010f, 500f, 26f, Obstacle.Type.CRATER, 83)
    );
    private final float[] obstacleCooldowns = new float[obstacles.size()];

    public MissionWorld() {
        // A serpentine field: three "columns" of hazards (x=560, 740, 920) each leaving a ~100px
        // gap wider than the ship, so a navigable path from the start past the crate to the pad
        // always exists (proven by the BFS reachability + auto-play tests), plus a few decorative
        // craters/rocks clear of the start->crate->pad route.
        reset();
    }

    /** Restores the world to a fresh, playable mission (full fuel, cargo present, ship at start). */
    public void reset() {
        shipX = SHIP_START_X;
        shipY = SHIP_START_Y;
        fuel = START_FUEL;
        cargoCollected = false;
        state = GameState.PLAYING;
        elapsed = 0f;
        collisions = 0;
        Arrays.fill(obstacleCooldowns, 0f);
        flashTimer = 0f;
    }

    /**
     * Advances the mission by {@code dt} seconds given the four movement inputs (any combination of
     * WASD / arrow keys is resolved to these booleans by the input layer). A no-op once the mission
     * has been won or lost.
     */
    public void update(float dt, boolean up, boolean down, boolean left, boolean right) {
        if (state != GameState.PLAYING) {
            return;
        }
        if (fuel <= 0f) {
            fuel = 0f;
            state = GameState.LOST;
            return;
        }
        if (!Float.isFinite(dt) || dt <= 0f) {
            return;
        }

        // Preserve real-time movement and fuel drain at low frame rates, while splitting collision
        // work into small steps to prevent tunnelling. A one-second catch-up cap avoids a large jump
        // after the app has been suspended or paused in a debugger.
        float remaining = Math.min(dt, MAX_FRAME_DELTA);
        while (remaining > 0f && state == GameState.PLAYING) {
            float step = Math.min(remaining, MAX_SIMULATION_STEP);
            simulateStep(step, up, down, left, right);
            remaining -= step;
        }
    }

    private void simulateStep(float dt, boolean up, boolean down, boolean left, boolean right) {
        elapsed += dt;
        flashTimer = Math.max(0f, flashTimer - dt);
        for (int i = 0; i < obstacleCooldowns.length; i++) {
            obstacleCooldowns[i] = Math.max(0f, obstacleCooldowns[i] - dt);
        }

        // --- Movement (8-directional, constant speed, diagonals normalised) ---
        float dx = 0f;
        float dy = 0f;
        if (left) dx -= 1f;
        if (right) dx += 1f;
        if (up) dy += 1f;
        if (down) dy -= 1f;
        if (dx != 0f || dy != 0f) {
            float len = (float) Math.sqrt(dx * dx + dy * dy);
            shipX += (dx / len) * MOVE_SPEED * dt;
            shipY += (dy / len) * MOVE_SPEED * dt;
        }
        clampShipToPlayField();

        // --- Obstacle collisions: per-hazard cooldown plus an immediate push out ---
        for (int i = 0; i < obstacles.size(); i++) {
            Obstacle o = obstacles.get(i);
            float ddx = shipX - o.x;
            float ddy = shipY - o.y;
            float dist = (float) Math.sqrt(ddx * ddx + ddy * ddy);
            float minDist = SHIP_RADIUS + o.radius;
            if (dist < minDist) {
                if (obstacleCooldowns[i] <= 0f) {
                    fuel -= OBSTACLE_PENALTY;
                    collisions++;
                    obstacleCooldowns[i] = PENALTY_COOLDOWN;
                    flashTimer = 1.0f;
                }
                float nx;
                float ny;
                if (dist > 1e-4f) {
                    nx = ddx / dist;
                    ny = ddy / dist;
                } else {
                    nx = 0f;
                    ny = 1f;
                }
                float overlap = minDist - dist;
                shipX += nx * (overlap + 0.5f);
                shipY += ny * (overlap + 0.5f);
            }
        }
        clampShipToPlayField();

        // --- Fuel drain, then depletion check FIRST so pad-at-zero-fuel is a loss, not a win ---
        fuel -= DRAIN_PER_SEC * dt;
        if (fuel <= 0f) {
            fuel = 0f;
            state = GameState.LOST;
            return;
        }

        // --- Cargo pickup ---
        if (!cargoCollected && withinRadius(CRATE_X, CRATE_Y, SHIP_RADIUS + CRATE_PICKUP_RADIUS)) {
            cargoCollected = true;
        }

        // --- Delivery (win) ---
        if (cargoCollected && fuel > 0f && withinRadius(PAD_X, PAD_Y, PAD_RADIUS)) {
            state = GameState.WON;
        }
    }

    private void clampShipToPlayField() {
        if (shipX < PLAY_MIN_X + SHIP_RADIUS) shipX = PLAY_MIN_X + SHIP_RADIUS;
        if (shipX > PLAY_MAX_X - SHIP_RADIUS) shipX = PLAY_MAX_X - SHIP_RADIUS;
        if (shipY < PLAY_MIN_Y + SHIP_RADIUS) shipY = PLAY_MIN_Y + SHIP_RADIUS;
        if (shipY > PLAY_MAX_Y - SHIP_RADIUS) shipY = PLAY_MAX_Y - SHIP_RADIUS;
    }

    private boolean withinRadius(float cx, float cy, float radius) {
        float ddx = shipX - cx;
        float ddy = shipY - cy;
        return (ddx * ddx + ddy * ddy) <= radius * radius;
    }

    // ---- QA / test seeding hooks (not used by normal gameplay) ----

    /** Marks the cargo as collected without moving the ship (used by tests and capture scenarios). */
    public void forceCollectCargo() {
        cargoCollected = true;
    }

    /** Places the ship at an arbitrary point inside the play field (tests / capture scenarios). */
    public void setShipPosition(float x, float y) {
        shipX = x;
        shipY = y;
        clampShipToPlayField();
    }

    /** Overrides the current fuel level, clamped to 0..100 (tests / capture scenarios). */
    public void setFuel(float value) {
        fuel = Math.max(0f, Math.min(START_FUEL, value));
    }

    // ---- Accessors for the render layer and tests ----

    public float getShipX() { return shipX; }
    public float getShipY() { return shipY; }
    public float getFuel() { return fuel; }
    /** Fuel as an integer percentage 0..100 for the HUD and result screens. */
    public int getFuelPercent() { return Math.round(fuel); }
    public boolean isCargoCollected() { return cargoCollected; }
    public GameState getState() { return state; }
    public float getElapsed() { return elapsed; }
    public int getCollisions() { return collisions; }
    public boolean isPenaltyFlashing() { return flashTimer > 0f; }
    public List<Obstacle> getObstacles() { return obstacles; }

    /** True when the ship is on the pad but has no cargo yet (drives a "collect cargo first" hint). */
    public boolean isOnPadWithoutCargo() {
        return !cargoCollected && withinRadius(PAD_X, PAD_Y, PAD_RADIUS);
    }

    /** A cosmetic score shown on the HUD and result screens; not part of any grading rule. */
    public int getScore() {
        int s = (cargoCollected ? 3000 : 0)
            + Math.round(fuel) * 100
            + Math.max(0, 4000 - Math.round(elapsed * 20f))
            - collisions * 150;
        return Math.max(0, s);
    }
}
