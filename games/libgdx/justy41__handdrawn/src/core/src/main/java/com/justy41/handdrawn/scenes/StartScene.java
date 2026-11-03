package com.justy41.handdrawn.scenes;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.justy41.handdrawn.components.*;
import com.justy41.handdrawn.core.Scene;
import com.justy41.handdrawn.systems.*;

public class StartScene extends Scene {
    int templateMap;

    @Override
    public void start(SpriteBatch batch) {
        super.start(batch);

        // First you need a Tiled map entity (an entity with the TiledComponent)
        templateMap = ecs.createEntity();
        ecs.addComponent(templateMap, ecs.tiledComponents, new TiledComponent("tilemaps/test_map.tmx"));

        // Only after that you can load the objects
        LoadSystems.loadTiledObjects(ecs);
    }

    @Override
    public void update(float deltaTime) {
        super.update(deltaTime);

        PlayerSystems.update(ecs, deltaTime);
        UpdateSystems.updatePosition(ecs, deltaTime);
        CameraSystems.cameraFollow(ecs, templateMap, deltaTime);
    }

    @Override
    public void render(SpriteBatch batch) {
        super.render(batch);

        tiledMapRenderer.setView(ecs.camera);
        RenderSystems.renderTiledMapLayers(ecs, tiledMapRenderer, new int[]{0,1,2,3,4,5});
        batch.begin();
        RenderSystems.drawTextures(ecs, batch);
        batch.end();
        RenderSystems.renderTiledMapLayers(ecs, tiledMapRenderer, new int[]{7,8,9});
        batch.begin();
        RenderSystems.debugRender(ecs, batch);
        batch.end();
    }
}
