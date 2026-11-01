package com.micro1.gladiatorarena;

import com.badlogic.gdx.math.Rectangle;

/**
 * An enemy gladiator: a red circle centred on (x, y) with hit points. Collisions use the AABB
 * bounding box of the circle (per the prompt's "AABB for all entities" rule).
 */
public class Enemy {

    public float x;
    public float y;
    public float hp;

    private final Rectangle bounds = new Rectangle();

    public Enemy(float x, float y) {
        this.x = x;
        this.y = y;
        this.hp = ArenaWorld.ENEMY_HP;
    }

    /** AABB bounds (28x28), reused (no per-frame allocation). */
    public Rectangle bounds() {
        float d = ArenaWorld.ENEMY_RADIUS * 2f;
        bounds.set(x - ArenaWorld.ENEMY_RADIUS, y - ArenaWorld.ENEMY_RADIUS, d, d);
        return bounds;
    }
}
