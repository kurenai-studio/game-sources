package com.github.br.libgdx.jam38.structure.ui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.InputProcessor;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.maps.*;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapImageLayer;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.utils.ObjectMap;
import com.badlogic.gdx.utils.viewport.Viewport;

public class CustomOrthogonalTiledMapRenderer extends OrthogonalTiledMapRenderer {

    private final ObjectMap<String, Stage> stages = new ObjectMap<>();
    private final Viewport viewport;
    private final ActorFactory actorFactory;
    private final InputMultiplexer inputMultiplexer;

    public CustomOrthogonalTiledMapRenderer(
        ActorFactory actorFactory, Viewport viewport, TiledMap map, float unitScale
    ) {
        super(map, unitScale);
        this.viewport = viewport;
        this.actorFactory = actorFactory;

        clampToEdgeTextures(map);

        inputMultiplexer = new InputMultiplexer();
        createStageActors(inputMultiplexer, map.getLayers());
    }

    @Override
    public void renderObjects(MapLayer layer) {
        // Рендерим Stage
        Stage stage = getStageByLayerName(layer.getName());
        stage.getViewport().apply();
        stage.act(Gdx.graphics.getDeltaTime());
        stage.getRoot().draw(batch, 1f);
    }

    public void updateOffsetsForGroupLayer(String layerName, float offsetX, float offsetY) {
        MapLayer mapLayer = getMap().getLayers().get(layerName);
        mapLayer.setOffsetX(offsetX);
        mapLayer.setOffsetY(offsetY);

        if (!(mapLayer instanceof MapGroupLayer)) {
            throw new IllegalArgumentException("Layer [" + layerName + "] is not MapGroupLayer");
        }

        MapGroupLayer groupLayer = (MapGroupLayer) mapLayer;

        for (MapLayer layerLayer : groupLayer.getLayers()) {
            // Двигаем слой через его позицию, а не offset
            if (layerLayer instanceof TiledMapImageLayer) {
                TiledMapImageLayer imageLayer = (TiledMapImageLayer) layerLayer;
                imageLayer.setX(imageLayer.getX() + offsetX);
                imageLayer.setY(imageLayer.getY() + offsetY);
            } else {
                layerLayer.setOffsetX(layerLayer.getOffsetX() + offsetX);
                layerLayer.setOffsetY(layerLayer.getOffsetY() + offsetY);
            }
            layerLayer.invalidateRenderOffset();

            Stage stage = stages.get(layerLayer.getName());
            if (stage != null) {
                for (Actor actor : stage.getActors()) {
                    actor.setX(actor.getX() + offsetX);
                    actor.setY(actor.getY() + offsetY);
                }
            }
        }
    }

    public void resize(int width, int height) {
        viewport.update(width, height);
        for (Stage stage : stages.values()) {
            stage.getViewport().update(width, height, true);
        }
    }

    private void clampToEdgeTextures(TiledMap tiledMap) {
        for (MapLayer layer : tiledMap.getLayers()) {
            if (layer instanceof TiledMapImageLayer) {
                ((TiledMapImageLayer) layer).getTextureRegion().getTexture().setWrap(
                    Texture.TextureWrap.ClampToEdge, Texture.TextureWrap.ClampToEdge
                );
            }
        }
    }

    private void createStageActors(InputMultiplexer inputMultiplexer, MapLayers mapLayers) {
        for (MapLayer layer : mapLayers) {
            if (layer instanceof MapGroupLayer) {
                MapLayers layers = ((MapGroupLayer) layer).getLayers();
                createStageActors(inputMultiplexer, layers);
            }

            MapObjects objects = layer.getObjects();
            if (objects == null || objects.getCount() == 0) {
                continue;
            }

            Stage stage = new Stage(viewport, getBatch());
            for (MapObject object : objects) {
                Actor actor = actorFactory.getActor(object);
                MapProperties properties = object.getProperties();
                float x = properties.get("x", float.class);
                float y = properties.get("y", float.class);
                float width = properties.get("width", Float.class);
                float height = properties.get("height", Float.class);
                actor.setBounds(x, y, width, height);

                actor.setName(object.getName());
                stage.addActor(actor);
            }

            stages.put(layer.getName(), stage);
            inputMultiplexer.addProcessor(stage);
        }
    }

    public InputProcessor getInputProcessor() {
        return inputMultiplexer;
    }

    public MapLayer getLayer(String layerName) {
        return getMap().getLayers().get(layerName);
    }

    public <T extends Actor> T getActor(String layerName, String actorName, Class<T> clazz) {
        Stage stage = stages.get(layerName);
        if (stage == null) {
            throw new IllegalArgumentException("unknown layer: " + layerName);
        }

        return clazz.cast(stage.getRoot().findActor(actorName));
    }

    public Stage getStageByLayerName(String layerName) {
        Stage stage = stages.get(layerName);
        if (stage == null) {
            throw new IllegalArgumentException("stage [" + layerName + "] is not found");
        }
        return stage;
    }

}
