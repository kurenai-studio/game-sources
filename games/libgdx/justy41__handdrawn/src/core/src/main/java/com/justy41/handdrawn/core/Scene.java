package com.justy41.handdrawn.core;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;

public class Scene {
    public Ecs ecs;
    public SceneManager sceneManager;
    public OrthogonalTiledMapRenderer tiledMapRenderer;

    public Scene() {
        ecs = new Ecs();
        ecs.camera = new OrthographicCamera(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        ecs.camera.setToOrtho(false);
    }

    public void start(SpriteBatch batch) {
        tiledMapRenderer = new OrthogonalTiledMapRenderer(null, batch);
        tiledMapRenderer.setView(ecs.camera);
    }

    public void update(float deltaTime) {
        if(ecs != null && ecs.camera != null) {
            ecs.camera.update();
        }
    }

    public void render(SpriteBatch batch) {
        if(ecs != null && ecs.camera != null) {
            batch.setProjectionMatrix(ecs.camera.combined);
        }
    }
}
