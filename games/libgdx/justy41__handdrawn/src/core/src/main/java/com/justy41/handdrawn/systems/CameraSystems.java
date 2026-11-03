package com.justy41.handdrawn.systems;

import com.badlogic.gdx.maps.Map;
import com.badlogic.gdx.math.MathUtils;
import com.justy41.handdrawn.components.SpriteRenderer;
import com.justy41.handdrawn.components.TiledComponent;
import com.justy41.handdrawn.components.TransformComponent;
import com.justy41.handdrawn.core.Ecs;

public class CameraSystems {
    public static void cameraFollow(Ecs ecs, int mapEntity, float deltaTime) {
        ecs.players.forEach((entity, player) -> {
            if(player != null && ecs.transforms.get(entity) != null && ecs.spriteRenderers.get(entity) != null && ecs.tiledComponents.get(mapEntity) != null) {
                TransformComponent t = ecs.transforms.get(entity);
                SpriteRenderer sr = ecs.spriteRenderers.get(entity);
                TiledComponent tiledComponent = ecs.tiledComponents.get(mapEntity);

                if(tiledComponent.map.getProperties().get("tileheight") == null) System.out.println(true);
                int mapWidth = (int)tiledComponent.map.getProperties().get("width")*(int)tiledComponent.map.getProperties().get("tilewidth");
                int mapHeight = (int)tiledComponent.map.getProperties().get("height")*(int)tiledComponent.map.getProperties().get("tileheight");

                ecs.camera.position.x = MathUtils.lerp(ecs.camera.position.x, t.position.x+sr.origin.x, deltaTime*2);
                ecs.camera.position.x = MathUtils.clamp(ecs.camera.position.x, ecs.camera.viewportWidth/2, mapWidth-ecs.camera.viewportWidth/2);

                ecs.camera.position.y = MathUtils.lerp(ecs.camera.position.y, t.position.y+sr.origin.y, deltaTime*2);

                // Comment the next line to disable camera bounds on y
                ecs.camera.position.y = MathUtils.clamp(ecs.camera.position.y, ecs.camera.viewportHeight/2, mapHeight-ecs.camera.viewportHeight/2);
            }
        });
    }
}
