package com.veilfall.game.rendering;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g3d.ModelBatch;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import java.util.Collections;
import com.veilfall.game.world.World;

public final class Renderer implements com.badlogic.gdx.utils.Disposable {
    private final CameraController cameraController;
    private final Lighting lighting;
    private final ModelBatch modelBatch;
    private World world;
    private com.badlogic.gdx.graphics.Color clearColor = new com.badlogic.gdx.graphics.Color(0.035f, 0.055f, 0.065f, 1f);

    public Renderer(int screenWidth, int screenHeight) {
        cameraController = new CameraController(screenWidth, screenHeight);
        lighting = new Lighting();
        modelBatch = new ModelBatch();
        world = new World();
    }

    public CameraController getCameraController() {
        return cameraController;
    }

    public void render() {
        render(Collections.emptyList());
    }

    public void setArenaEnvironment(String environment) {
        world.dispose();
        world = new World(environment);
        lighting.setBiome(environment);
        clearColor = switch (environment == null ? "MISTWOOD" : environment.toUpperCase()) {
            case "ASHEN" -> new com.badlogic.gdx.graphics.Color(0.11f, 0.045f, 0.035f, 1f);
            case "DROWNED" -> new com.badlogic.gdx.graphics.Color(0.025f, 0.09f, 0.14f, 1f);
            default -> new com.badlogic.gdx.graphics.Color(0.025f, 0.075f, 0.055f, 1f);
        };
    }

    public void render(Iterable<ModelInstance> additionalInstances) {
        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);
        Gdx.gl.glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT);

        modelBatch.begin(cameraController.getCamera());
        for (ModelInstance instance : world.getInstances()) {
            modelBatch.render(instance, lighting.getEnvironment());
        }
        for (ModelInstance instance : additionalInstances) {
            modelBatch.render(instance, lighting.getEnvironment());
        }
        modelBatch.end();
    }

    public void resize(int width, int height) {
        if (width <= 0 || height <= 0) {
            return;
        }
        Gdx.gl.glViewport(0, 0, width, height);
        cameraController.resize(width, height);
    }

    @Override
    public void dispose() {
        modelBatch.dispose();
        world.dispose();
    }
}
