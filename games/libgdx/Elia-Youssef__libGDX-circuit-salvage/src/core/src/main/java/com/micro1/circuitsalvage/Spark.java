package com.micro1.circuitsalvage;

import com.badlogic.gdx.math.Rectangle;

/**
 * A moving spark hazard. Travels back and forth along one axis between {@code minBound} and
 * {@code maxBound}, reversing direction exactly at each bound (never overshooting past it).
 */
public final class Spark {

    public static final float SIZE = 32f;
    public static final float SPEED = 96f;

    private final SparkAxis axis;
    private final float fixedCoordinate;
    private final float minBound;
    private final float maxBound;
    private final float startPos;
    private final int startDirection;

    private float pos;
    private int direction;
    private final Rectangle bounds = new Rectangle(0, 0, SIZE, SIZE);

    public Spark(SparkAxis axis, float fixedCoordinate, float minBound, float maxBound,
                 float startPos, int startDirection) {
        this.axis = axis;
        this.fixedCoordinate = fixedCoordinate;
        this.minBound = minBound;
        this.maxBound = maxBound;
        this.startPos = startPos;
        this.startDirection = startDirection;
        reset();
    }

    public void reset() {
        pos = startPos;
        direction = startDirection;
        updateBounds();
    }

    public void update(float delta) {
        pos += direction * SPEED * delta;
        if (pos > maxBound) {
            pos = maxBound;
            direction = -1;
        } else if (pos < minBound) {
            pos = minBound;
            direction = 1;
        }
        updateBounds();
    }

    private void updateBounds() {
        bounds.set(getCenterX() - SIZE / 2f, getCenterY() - SIZE / 2f, SIZE, SIZE);
    }

    public float getCenterX() {
        return axis == SparkAxis.HORIZONTAL ? pos : fixedCoordinate;
    }

    public float getCenterY() {
        return axis == SparkAxis.VERTICAL ? pos : fixedCoordinate;
    }

    public SparkAxis getAxis() {
        return axis;
    }

    public Rectangle getBounds() {
        return bounds;
    }

    public boolean overlaps(Rectangle playerBounds) {
        return bounds.overlaps(playerBounds);
    }
}
