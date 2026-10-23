package com.jgarivera.blitzbit.graphics;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.OrthographicCamera;

public class Camera extends OrthographicCamera {

    public static final float MIN_ZOOM = 1.0f;
    public static final float MAX_ZOOM = 2.5f;
    /**
     * The viewport width in meters.
     */
    public static final float VIEWPORT_WIDTH = 10;
    /**
     * The viewport height in meters.
     */
    public static final float VIEWPORT_HEIGHT = 10;
    private static final float SCREEN_WIDTH = Gdx.graphics.getWidth();
    private static final float SCREEN_HEIGHT = Gdx.graphics.getHeight();

    protected final float maxZoom;
    protected final float minZoom;

    public Camera() {
        this(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, MIN_ZOOM, MAX_ZOOM);
    }

    public Camera(float viewportWidth, float viewportHeight, float minZoom, float maxZoom) {
        super(viewportWidth, viewportHeight);

        this.minZoom = minZoom;
        this.maxZoom = maxZoom;
        Gdx.app.debug("GameCamera", String.format("Created game camera with a viewport size: %.2fm by %.2fm", VIEWPORT_WIDTH, VIEWPORT_HEIGHT));
    }

    public void zoomIn(float units) {
        zoom -= units * 0.25f;

        if (zoom <= minZoom) {
            zoom = minZoom;
        }
    }

    public void zoomOut(float units) {
        zoom += units * 0.25f;

        if (zoom > maxZoom) {
            zoom = maxZoom;
        }
    }

    public void resetZoom() {
        zoom = 1.0f;
    }

    public void follow(float x, float y) {
        position.set(x, y, 0.0f);
        update();
    }

    public void followLerp(float followX, float followY, float interpolation) {
        float cameraX = position.x;
        float cameraY = position.y;

        follow(cameraX + (followX - cameraX) * interpolation, cameraY + (followY - cameraY) * interpolation);
    }

    public void resize(int screenWidth, int screenHeight, float viewportWidthMeters, float viewportHeightMeters) {
        float viewportWidthRatio = viewportWidthMeters / screenWidth;
        float viewportHeightRatio = viewportHeightMeters / screenHeight;

        viewportHeight = viewportWidthRatio * screenHeight;
        follow(viewportWidthRatio / 2.0f, viewportHeightRatio / 2.0f);
    }
}
