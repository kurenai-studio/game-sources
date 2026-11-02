package com.ychstudio.builders;

import com.badlogic.ashley.core.Engine;
import com.badlogic.gdx.maps.MapLayer;
import com.badlogic.gdx.maps.MapLayers;
import com.badlogic.gdx.maps.MapObject;
import com.badlogic.gdx.maps.MapObjects;
import com.badlogic.gdx.maps.objects.PolygonMapObject;
import com.badlogic.gdx.maps.objects.RectangleMapObject;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapTileLayer;
import com.badlogic.gdx.math.Polygon;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.physics.box2d.World;
import com.ychstudio.gamesys.GameManager;

public class WorldBuilder {

    private static final WorldBuilder instance = new WorldBuilder();

    private World world;
    private Engine engine;

    private TiledMap tiledMap;

    private int mapWidth = 0;
    private int mapHeight = 0;

    private WorldBuilder() {
    }

    public static WorldBuilder getInstance(World world, Engine engine) {
        instance.world = world;
        instance.engine = engine;
        return instance;
    }

    public TiledMap loadTiledMap(String mapFile) {
        tiledMap = GameManager.assetManager.get("maps/" + mapFile, TiledMap.class);
        ActorBuilder actorBuilder = ActorBuilder.getInstance(world, engine);

        MapLayers mapLayers = tiledMap.getLayers();

        TiledMapTileLayer groundLayer = (TiledMapTileLayer) mapLayers.get("Ground");
        mapWidth = groundLayer.getWidth();
        mapHeight = groundLayer.getHeight();

        GameManager.moveBound.set(0, 0, groundLayer.getWidth(), groundLayer.getHeight());

        // load obstacles
        MapLayer obstacleLayer = mapLayers.get("Obstacles");
        if (obstacleLayer != null) {
            for (MapObject mapObject : obstacleLayer.getObjects()) {
                if (mapObject instanceof RectangleMapObject) {
                    Rectangle rectangle = ((RectangleMapObject) mapObject).getRectangle();
                    correctRectangle(rectangle);

                    actorBuilder.createObstacle(rectangle);

                } else if (mapObject instanceof PolygonMapObject) {
                    Polygon polygon = ((PolygonMapObject) mapObject).getPolygon();

                    float[] vertices = polygon.getVertices();

                    for (int i = 0; i < vertices.length; i++) {
                        vertices[i] = vertices[i] / GameManager.PPM;
                    }
                    actorBuilder.createObstacle(polygon.getX() / GameManager.PPM, polygon.getY() / GameManager.PPM,
                            vertices);
                }
            }
        }

        // load tents
        MapLayer tentLayer = mapLayers.get("Tents");
        if (tentLayer != null) {
            for (MapObject mapObject : tentLayer.getObjects()) {
                Rectangle rectangle = ((RectangleMapObject) mapObject).getRectangle();
                correctRectangle(rectangle);

                actorBuilder.createTent(rectangle.x + rectangle.width / 2f, rectangle.y + rectangle.height / 2f);
            }
        }

        // load farms
        MapLayer farmLayer = mapLayers.get("Farms");
        if (farmLayer != null) {
            for (MapObject mapObject : farmLayer.getObjects()) {
                Rectangle rectangle = ((RectangleMapObject) mapObject).getRectangle();
                correctRectangle(rectangle);

                actorBuilder.createFarm(rectangle);
            }
        }

        // TODO: load buildings

        // TODO: load animals

        // TODO: load enemies

        // load player
        MapLayer playerLayer = mapLayers.get("Player");
        if (playerLayer != null) {
            MapObjects playerObjects = playerLayer.getObjects();
            Rectangle rectangle = ((RectangleMapObject) (playerObjects.get(0))).getRectangle();

            correctRectangle(rectangle);

            actorBuilder.createPlayer(rectangle.x + rectangle.width / 2, rectangle.y + rectangle.height / 2);
            GameManager.playerSpawnPos.set(rectangle.x + rectangle.width / 2, rectangle.y + rectangle.height / 2);
        }

        return tiledMap;
    }

    private void correctRectangle(Rectangle rectangle) {
        rectangle.x /= GameManager.PPM;
        rectangle.y /= GameManager.PPM;
        rectangle.width /= GameManager.PPM;
        rectangle.height /= GameManager.PPM;
    }

    public TiledMap getTiledMap() {
        return tiledMap;
    }

    public int getMapWidth() {
        return mapWidth;
    }

    public int getMapHeight() {
        return mapHeight;
    }

}
