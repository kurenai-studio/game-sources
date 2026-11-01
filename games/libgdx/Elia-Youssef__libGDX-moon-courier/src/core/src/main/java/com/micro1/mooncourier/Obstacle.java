package com.micro1.mooncourier;

/**
 * One lunar hazard: a rock or a crater. Collision is a simple circle (centre + radius). The
 * {@code type} and {@code seed} only affect how it is drawn (craters as dark rimmed pits, rocks as
 * jagged grey blobs); the simulation treats every obstacle as a circle.
 */
public final class Obstacle {

    /** How the obstacle is rendered. Collision is identical for both. */
    public enum Type { ROCK, CRATER }

    public final float x;
    public final float y;
    public final float radius;
    public final Type type;
    /** Fixed per-obstacle seed so the drawn rock/crater shape is stable frame to frame. */
    public final int seed;

    public Obstacle(float x, float y, float radius, Type type, int seed) {
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.type = type;
        this.seed = seed;
    }
}
