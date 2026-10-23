package com.jgarivera.blitzbit.graphics;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector3;
import com.jgarivera.blitzbit.world.World;

public class Overlay {

    private final World world;
    private final SpriteBatch batch;
    private final BitmapFont font;

    public Overlay(World world) {
        this.world = world;
        batch = new SpriteBatch();
        font = new BitmapFont();
    }

    public void render(float delta) {
        int screenHeight = Gdx.graphics.getHeight();

        batch.begin();
        renderFPSInformation(screenHeight);
        renderCameraInformation(screenHeight);
        batch.end();
    }

    private void renderFPSInformation(int screenHeight) {
        int fps = Gdx.graphics.getFramesPerSecond();
        font.draw(batch, String.format("FPS: %d", fps), 15, screenHeight - 15);
    }

    private void renderCameraInformation(int screenHeight) {
        Camera camera = world.getCamera();
        Vector3 cameraPos = camera.position;
        font.draw(batch, String.format("cam_x: %.2fm, cam_y: %.2fm", cameraPos.x, cameraPos.y), 15, screenHeight - 30);
        font.draw(batch, String.format("cam_zoom: %.2f", camera.zoom), 15, screenHeight - 45);
    }

    public void resize(int width, int height) {
        batch.getProjectionMatrix().setToOrtho2D(0, 0, width, height);
    }
}
