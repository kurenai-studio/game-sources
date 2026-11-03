package com.justy41.handdrawn.systems;

import com.badlogic.gdx.maps.MapLayer;
import com.badlogic.gdx.maps.MapObject;
import com.badlogic.gdx.maps.objects.RectangleMapObject;
import com.badlogic.gdx.math.Rectangle;
import com.justy41.handdrawn.components.*;
import com.justy41.handdrawn.core.Ecs;

import java.util.ArrayList;

public class LoadSystems {
    public static void loadTiledObjects(Ecs ecs) {
        ArrayList<MapObject> objectsToLoad = new ArrayList<>();

        ecs.tiledComponents.forEach((entity, tiledComponent) -> {
            if(tiledComponent != null) {
                if(tiledComponent.map.getLayers().get("Entities") != null) {
                    MapLayer objectLayer = tiledComponent.map.getLayers().get("Entities");

                    for(MapObject obj : objectLayer.getObjects()) {
                        objectsToLoad.add(obj);
                    }
                }
            }
        });

        for(MapObject obj : objectsToLoad) {
            loadTiledObject(ecs, obj);
        }
    }


    public static void loadTiledObject(Ecs ecs, MapObject obj) {
        if(obj instanceof RectangleMapObject) {
            RectangleMapObject rectObj = (RectangleMapObject)obj;
            Rectangle rect = rectObj.getRectangle();

            switch((String)obj.getProperties().get("Type")) {
                case "player":
                    int player = ecs.createEntity();
                    ecs.addComponent(player, ecs.transforms, new TransformComponent(rect.x, rect.y, 1, 1, 0));
                    ecs.addComponent(player, ecs.rigidbodies, new RigidBody(0, 0, 1200));
                    ecs.addComponent(player, ecs.spriteRenderers, new SpriteRenderer("sun_man.png", true));
                    ecs.addComponent(player, ecs.boxColliders, new BoxCollider(56, 35, rect.width, rect.height));
                    ecs.addComponent(player, ecs.players, new Player(300, 400));
                    ecs.players.get(player).gravity = ecs.rigidbodies.get(player).gravity;
                    break;
                case "box":
                    int box = ecs.createEntity();
                    ecs.addComponent(box, ecs.transforms, new TransformComponent(rect.x, rect.y, 1, 1, 0));
                    ecs.addComponent(box, ecs.rigidbodies, new RigidBody());
                    ecs.addComponent(box, ecs.spriteRenderers, new SpriteRenderer("brick.png"));
                    ecs.addComponent(box, ecs.boxColliders, new BoxCollider(0, 0, 16, 16));
                    break;
                case "collider":
                    createCollider(ecs, rect.x, rect.y, rect.width, rect.height);
            }
        }
    }

    public static void createCollider(Ecs ecs, float x, float y, float width, float height) {
        int box = ecs.createEntity();
        ecs.addComponent(box, ecs.transforms, new TransformComponent(x, y, 1, 1, 0));
        ecs.addComponent(box, ecs.rigidbodies, new RigidBody());
        ecs.addComponent(box, ecs.boxColliders, new BoxCollider(0, 0, width, height));
    }
}
