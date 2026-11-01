package com.veilfall.game.rendering;

import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;

public final class CameraController extends InputAdapter {
    private static final float BASE_VIEW_HEIGHT = 34f;
    private static final float MIN_ZOOM = 0.65f;
    private static final float MAX_ZOOM = 2.5f;

    private final OrthographicCamera orthographicCamera = new OrthographicCamera();
    private final PerspectiveCamera perspectiveCamera = new PerspectiveCamera();
    private final Vector3 target = new Vector3(0f, 0f, 0f);
    private final Vector3 viewOffset = new Vector3(21f, 27f, 21f);

    private Projection projection = Projection.ORTHOGRAPHIC;
    private float zoom = 1f;
    private int screenWidth = 1;
    private int screenHeight = 1;

    public CameraController(int screenWidth, int screenHeight) {
        resize(screenWidth, screenHeight);
    }

    public Camera getCamera() {
        return projection == Projection.ORTHOGRAPHIC ? orthographicCamera : perspectiveCamera;
    }

    public void setTargetPosition(float x, float z) {
        target.set(x, 0f, z);
        updateCameras();
    }

    public void resize(int width, int height) {
        screenWidth = Math.max(width, 1);
        screenHeight = Math.max(height, 1);
        updateCameras();
    }

    @Override
    public boolean keyDown(int keycode) {
        if (keycode != Input.Keys.P) {
            return false;
        }
        projection = projection == Projection.ORTHOGRAPHIC
                ? Projection.PERSPECTIVE
                : Projection.ORTHOGRAPHIC;
        updateCameras();
        return true;
    }

    @Override
    public boolean scrolled(float amountX, float amountY) {
        zoom = MathUtils.clamp(zoom * (float) Math.pow(1.12f, -amountY), MIN_ZOOM, MAX_ZOOM);
        updateCameras();
        return true;
    }

    private void updateCameras() {
        float aspect = screenWidth / (float) screenHeight;

        orthographicCamera.viewportHeight = BASE_VIEW_HEIGHT / zoom;
        orthographicCamera.viewportWidth = orthographicCamera.viewportHeight * aspect;
        setView(orthographicCamera, 1f);

        perspectiveCamera.fieldOfView = 50f;
        perspectiveCamera.viewportWidth = screenWidth;
        perspectiveCamera.viewportHeight = screenHeight;
        perspectiveCamera.near = 0.1f;
        perspectiveCamera.far = 120f;
        setView(perspectiveCamera, 1f / zoom);
    }

    private void setView(Camera camera, float distanceScale) {
        camera.position.set(target).mulAdd(viewOffset, distanceScale);
        camera.up.set(Vector3.Y);
        camera.lookAt(target);
        camera.update();
    }

    public enum Projection {
        ORTHOGRAPHIC,
        PERSPECTIVE
    }
}
