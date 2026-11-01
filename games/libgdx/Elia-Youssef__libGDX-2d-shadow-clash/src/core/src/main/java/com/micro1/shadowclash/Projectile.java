package com.micro1.shadowclash;

import com.badlogic.gdx.math.Rectangle;

/**
 * A Shadow Blast projectile. Travels independently across the stage with its own collision box
 * and continuously checks for overlap with the opponent's hurtbox (handled in {@link ClashWorld}).
 * On impact it is removed, 5 damage is applied (unless blocked), and an impact effect + slow motion
 * are triggered. It also despawns at the arena edge.
 */
public final class Projectile {
    public static final float W = 70f, H = 46f;

    public final Fighter owner;   // who fired it (its opponent is the target)
    public final int facing;      // travel direction (+1 right, -1 left)
    public float x, y;            // centre
    public float age;
    public boolean alive = true;

    public Projectile(Fighter owner, float x, float y, int facing) {
        this.owner = owner; this.x = x; this.y = y; this.facing = facing;
    }

    public void update(float dt) {
        x += K.PROJECTILE_SPEED * facing * dt;
        age += dt;
        if (x < -60f || x > K.WORLD_W + 60f) alive = false;
    }

    public Rectangle box(Rectangle r) {
        return r.set(x - W / 2f, y - H / 2f, W, H);
    }
}
