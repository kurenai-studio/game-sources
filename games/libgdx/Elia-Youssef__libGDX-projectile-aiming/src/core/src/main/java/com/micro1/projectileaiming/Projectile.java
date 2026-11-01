package com.micro1.projectileaiming;

import com.badlogic.gdx.math.Vector2;

/**
 * A single launched projectile: position and velocity in world units (pixels), advanced by
 * semi-implicit (symplectic) Euler under a constant downward gravity.
 *
 * The exact same {@link #step(float, float)} integrator drives both the live projectile and
 * the aiming preview (see {@link ProjectileAimingApp}). Stepping identical launch state with
 * the identical fixed timestep is what makes the dotted preview match the real flight to the
 * pixel: the fired shot literally passes through the previewed points at matching step counts.
 */
public class Projectile {

    public final Vector2 position = new Vector2();
    public final Vector2 velocity = new Vector2();

    /** Reset to a fresh launch state at the given origin and initial velocity. */
    public void launch(float x, float y, float vx, float vy) {
        position.set(x, y);
        velocity.set(vx, vy);
    }

    /**
     * Advance one step of {@code dt} seconds. Semi-implicit Euler: apply gravity to the
     * velocity first, then the updated velocity to the position. The preview replays this
     * exact ordering, so both share one discrete trajectory.
     */
    public void step(float dt, float gravity) {
        velocity.y += gravity * dt;
        position.x += velocity.x * dt;
        position.y += velocity.y * dt;
    }
}
