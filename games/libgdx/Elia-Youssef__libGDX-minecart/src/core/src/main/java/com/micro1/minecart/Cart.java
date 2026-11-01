package com.micro1.minecart;

import com.badlogic.gdx.math.Rectangle;

/**
 * A single mine cart. Position is the top-left corner in the game's top-left-origin space
 * (x increases right, y increases downward). {@code destination} is the cave it must reach
 * (0 upper, 1 middle, 2 lower); {@code assignedTrack} is the track it actually took at the
 * junction (set once {@code switched} becomes true).
 */
public class Cart {

    public float x;
    public float y;
    public final int destination;
    public int assignedTrack = MineCartWorld.MIDDLE;
    public boolean switched;

    private final Rectangle bounds = new Rectangle();

    public Cart(float x, float y, int destination) {
        this.x = x;
        this.y = y;
        this.destination = destination;
    }

    public float centerX() {
        return x + MineCartWorld.CART_W / 2f;
    }

    /** AABB bounds, reused (no per-frame allocation). */
    public Rectangle bounds() {
        bounds.set(x, y, MineCartWorld.CART_W, MineCartWorld.CART_H);
        return bounds;
    }
}
