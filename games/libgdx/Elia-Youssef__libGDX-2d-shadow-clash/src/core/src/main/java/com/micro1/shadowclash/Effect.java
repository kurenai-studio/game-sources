package com.micro1.shadowclash;

/**
 * A transient visual effect (hit spark, block spark, projectile impact, dash dust). Pure data:
 * the simulation spawns them and ages them; the render layer draws the matching fx_* animation.
 */
public final class Effect {
    public enum Kind { HIT, BLOCK, EXPLOSION, DUST }

    public final Kind kind;
    public final float x, y;
    public final int facing;
    public final float life;
    public float time;
    public boolean fromPlayer = true;  // which fighter's colour sheet renders this effect

    public Effect(Kind kind, float x, float y, int facing, float life) {
        this.kind = kind; this.x = x; this.y = y; this.facing = facing; this.life = life;
    }

    /** @return true while still alive. */
    public boolean update(float dt) {
        time += dt;
        return time < life;
    }

    public float progress() { return life <= 0 ? 1f : Math.min(1f, time / life); }
}
