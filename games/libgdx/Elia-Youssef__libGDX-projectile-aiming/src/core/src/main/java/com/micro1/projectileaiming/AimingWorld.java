package com.micro1.projectileaiming;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

/**
 * All simulation and game-state rules for the projectile-aiming prototype, with no libGDX
 * graphics/input dependency (only the pure math + collection types), so it can be exercised
 * headlessly. {@link ProjectileAimingApp} is a thin render/input shell over this.
 *
 * Two structural correctness guarantees:
 *   - Preview equals flight: {@link #buildPreview} steps a scratch {@link Projectile} with the
 *     same integrator and the same {@link #FIXED_DT} the live shot uses, from the same launch
 *     state, so the fired projectile passes through the previewed dots at matching step counts.
 *   - Frame-rate independence: {@link #update} advances a fixed-timestep accumulator, so the
 *     sequence of physics steps (hence every collision/landing) is identical at any frame rate.
 */
public class AimingWorld {

    // World (fixed 800x600, y-up, origin bottom-left).
    public static final float WORLD_W = 800f;
    public static final float WORLD_H = 600f;
    public static final float GROUND_TOP = 60f;

    // Physics.
    public static final float GRAVITY = -500f;      // px/s^2, downward
    public static final float MAX_SPEED = 600f;     // px/s reached at MAX_DRAG
    public static final float MAX_DRAG = 250f;      // px of cursor distance for full power
    public static final float FIXED_DT = 1f / 120f; // deterministic simulation step

    // Launcher muzzle = the fixed launch origin, near the bottom-left corner.
    public static final float LAUNCH_X = 78f;
    public static final float LAUNCH_Y = 104f;

    public static final float PROJECTILE_RADIUS = 8f;

    // Preview sampling.
    public static final int PREVIEW_STEP_STRIDE = 5; // emit a dot every N fixed steps
    public static final int MAX_PREVIEW_DOTS = 120;

    public static final float TARGET_RADIUS = 22f;
    public static final int TARGET_GOAL = 3;

    private final Array<Target> targets = new Array<Target>();
    private final Projectile projectile = new Projectile();
    private boolean projectileActive;
    private int hits;

    private boolean aiming;
    private final Vector2 aimVelocity = new Vector2();
    private final Array<Vector2> previewDots = new Array<Vector2>();

    // Scratch, reused to avoid per-frame allocation.
    private final Projectile scratch = new Projectile();
    private float accumulator;

    public AimingWorld() {
        reset();
    }

    /** Return to the initial state (fresh launch, three unhit targets, empty accumulator). */
    public void reset() {
        // All three centres sit inside the max-speed launch envelope
        // y <= LAUNCH_Y + MAX_SPEED^2/(2*|GRAVITY|) - |GRAVITY|*(x-LAUNCH_X)^2/(2*MAX_SPEED^2)
        // (= 464 - (x-78)^2/1440) with ~65-73 px of margin, so every target is hittable.
        // Verified by the reachability sweep + isolated real-fire test in the QA harness.
        targets.clear();
        targets.add(new Target(260f, 370f, TARGET_RADIUS));
        targets.add(new Target(440f, 300f, TARGET_RADIUS));
        targets.add(new Target(600f, 210f, TARGET_RADIUS));
        projectileActive = false;
        hits = 0;
        aiming = false;
        accumulator = 0f;
        previewDots.clear();
    }

    /**
     * Advance one rendered frame: apply the aim/fire input, then run the fixed-step simulation
     * for the elapsed time. {@code cursorX/cursorY} are in world coordinates.
     */
    public void update(float frameDt, boolean pressed, float cursorX, float cursorY) {
        handleInput(pressed, cursorX, cursorY);
        accumulator += Math.min(frameDt, 0.25f);
        while (accumulator >= FIXED_DT) {
            stepSimulation(FIXED_DT);
            accumulator -= FIXED_DT;
        }
    }

    private void handleInput(boolean pressed, float cursorX, float cursorY) {
        // While a shot is in flight the launcher is locked: no aiming, no firing.
        if (projectileActive) {
            aiming = false;
            previewDots.clear();
            return;
        }
        if (pressed) {
            // Hold-to-aim: recompute the aim from the current cursor and refresh the preview.
            if (computeAim(cursorX, cursorY, aimVelocity)) {
                aiming = true;
                buildPreview(aimVelocity);
            } else {
                aiming = false;
                previewDots.clear();
            }
        } else if (aiming) {
            // Release-to-fire: commit the shot that was being aimed.
            aiming = false;
            previewDots.clear();
            fire(aimVelocity);
        }
    }

    /**
     * Direction = launcher to cursor; power scales linearly with drag distance and is clamped
     * to {@link #MAX_SPEED} at {@link #MAX_DRAG}. Returns false when the cursor sits essentially
     * on the launcher (no usable direction).
     */
    private boolean computeAim(float cursorX, float cursorY, Vector2 outVelocity) {
        float dx = cursorX - LAUNCH_X;
        float dy = cursorY - LAUNCH_Y;
        float dist = (float) Math.sqrt(dx * dx + dy * dy);
        if (dist < 1f) {
            return false;
        }
        float power = Math.min(dist, MAX_DRAG) / MAX_DRAG * MAX_SPEED;
        outVelocity.set(dx / dist * power, dy / dist * power);
        return true;
    }

    private void fire(Vector2 velocity) {
        projectile.launch(LAUNCH_X, LAUNCH_Y, velocity.x, velocity.y);
        projectileActive = true;
    }

    /**
     * Simulate the aim forward with the same integrator and timestep the live shot uses,
     * emitting a preview dot every {@link #PREVIEW_STEP_STRIDE} steps until the arc would hit
     * the ground, an active target, or leave the screen horizontally.
     */
    private void buildPreview(Vector2 velocity) {
        previewDots.clear();
        scratch.launch(LAUNCH_X, LAUNCH_Y, velocity.x, velocity.y);
        int maxSteps = MAX_PREVIEW_DOTS * PREVIEW_STEP_STRIDE;
        for (int step = 1; step <= maxSteps; step++) {
            scratch.step(FIXED_DT, GRAVITY);
            if (isPreviewTerminal(scratch.position.x, scratch.position.y)) {
                break;
            }
            if (step % PREVIEW_STEP_STRIDE == 0) {
                previewDots.add(new Vector2(scratch.position.x, scratch.position.y));
                if (previewDots.size >= MAX_PREVIEW_DOTS) {
                    break;
                }
            }
        }
    }

    /** Stop the preview where the real shot would resolve: ground, an active target, or a side exit. */
    private boolean isPreviewTerminal(float x, float y) {
        if (y - PROJECTILE_RADIUS <= GROUND_TOP) {
            return true;
        }
        if (x + PROJECTILE_RADIUS < 0f || x - PROJECTILE_RADIUS > WORLD_W) {
            return true;
        }
        for (int i = 0; i < targets.size; i++) {
            Target t = targets.get(i);
            if (!t.hit && overlaps(x, y, t)) {
                return true;
            }
        }
        return false;
    }

    /** Advance the live projectile one fixed step and resolve target/ground/screen-exit outcomes. */
    private void stepSimulation(float dt) {
        if (!projectileActive) {
            return;
        }
        projectile.step(dt, GRAVITY);
        float x = projectile.position.x;
        float y = projectile.position.y;

        for (int i = 0; i < targets.size; i++) {
            Target t = targets.get(i);
            if (!t.hit && overlaps(x, y, t)) {
                t.hit = true;
                hits++;
                projectileActive = false;
                return;
            }
        }
        if (y - PROJECTILE_RADIUS <= GROUND_TOP) {
            projectileActive = false;
            return;
        }
        if (x + PROJECTILE_RADIUS < 0f || x - PROJECTILE_RADIUS > WORLD_W) {
            projectileActive = false;
        }
    }

    private boolean overlaps(float x, float y, Target t) {
        float dx = x - t.x;
        float dy = y - t.y;
        float rr = PROJECTILE_RADIUS + t.radius;
        return dx * dx + dy * dy <= rr * rr;
    }

    // Read-only views for the render layer / tests.
    public Array<Target> getTargets() {
        return targets;
    }

    public Projectile getProjectile() {
        return projectile;
    }

    public boolean isProjectileActive() {
        return projectileActive;
    }

    public boolean isAiming() {
        return aiming;
    }

    public int getHits() {
        return hits;
    }

    public Array<Vector2> getPreviewDots() {
        return previewDots;
    }
}
