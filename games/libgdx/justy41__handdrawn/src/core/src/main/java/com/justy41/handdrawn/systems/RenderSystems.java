package com.justy41.handdrawn.systems;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.math.Matrix4;
import com.justy41.handdrawn.components.BoxCollider;
import com.justy41.handdrawn.components.SpriteRenderer;
import com.justy41.handdrawn.components.TransformComponent;
import com.justy41.handdrawn.core.Ecs;

public class RenderSystems {
    public static void drawTextures(Ecs ecs, SpriteBatch batch) {
        ecs.transforms.forEach((entity, transform) -> {
            SpriteRenderer sr;
            sr = ecs.spriteRenderers.get(entity);

            if(transform != null && sr != null) {
                batch.draw(
                    sr.texture,
                    transform.position.x,
                    transform.position.y,
                    sr.origin.x, sr.origin.y,
                    sr.texture.getWidth(),
                    sr.texture.getHeight(),
                    transform.scale.x,
                    transform.scale.y,
                    transform.rotation,
                    0, 0,
                    sr.texture.getWidth(),
                    sr.texture.getHeight(),
                    sr.flipX,
                    sr.flipY
                );
            }
        });
    }

    public static void renderTiledMap(Ecs ecs, OrthogonalTiledMapRenderer tiledMapRenderer) {
        ecs.tiledComponents.forEach((entity, tiledComponent) -> {
            if(tiledComponent != null) {
                tiledMapRenderer.setMap(tiledComponent.map);
                tiledMapRenderer.render();
            }
        });
    }

    /**
     * Used to render Tiled layers separately in order to have a Parallax Effect.
     * For Parallax use (int Tiled) value 1 for camera speed and 0 for never moving.
     * Can't have negative values!
     * @param ecs
     * @param tiledMapRenderer
     * @param layers new int[]{...} that contains the indices of the Tiled layers (be aware that every layer counts, even Object Layers)
     */
    public static void renderTiledMapLayers(Ecs ecs, OrthogonalTiledMapRenderer tiledMapRenderer, int[] layers) {
        Matrix4 original = tiledMapRenderer.getBatch().getTransformMatrix().cpy();
        ecs.tiledComponents.forEach((entity, tiledComponent) -> {
            if(tiledComponent != null) {
                if(tiledComponent.map.getProperties().get("parallaxx") != null && tiledComponent.map.getProperties().get("parallaxy") != null) {
                    tiledMapRenderer.setMap(tiledComponent.map);
                    tiledMapRenderer.getBatch().getTransformMatrix().translate(tiledComponent.map.getProperties().get("parallaxx", Float.class), tiledComponent.map.getProperties().get("parallaxy", Float.class), 0);
                    tiledMapRenderer.render(layers);
                    tiledMapRenderer.getBatch().setTransformMatrix(original);
                }
                if(tiledComponent.map.getProperties().get("parallaxx") != null && tiledComponent.map.getProperties().get("parallaxy") == null) {
                    tiledMapRenderer.setMap(tiledComponent.map);
                    tiledMapRenderer.getBatch().getTransformMatrix().translate((float)tiledComponent.map.getProperties().get("parallaxx"), 0, 0);
                    tiledMapRenderer.render(layers);
                    tiledMapRenderer.getBatch().setTransformMatrix(original);
                }
                if(tiledComponent.map.getProperties().get("parallaxx") == null && tiledComponent.map.getProperties().get("parallaxy") != null) {
                    tiledMapRenderer.setMap(tiledComponent.map);
                    tiledMapRenderer.getBatch().getTransformMatrix().translate(0, (float)tiledComponent.map.getProperties().get("parallaxy"), 0);
                    tiledMapRenderer.render(layers);
                    tiledMapRenderer.getBatch().setTransformMatrix(original);
                }
                if(tiledComponent.map.getProperties().get("parallaxx") == null && tiledComponent.map.getProperties().get("parallaxy") == null) {
                    tiledMapRenderer.setMap(tiledComponent.map);
                    tiledMapRenderer.render(layers);
                    tiledMapRenderer.getBatch().setTransformMatrix(original);
                }
            }
        });
    }

    public static void debugRender(Ecs ecs, SpriteBatch batch) {
        ecs.boxColliders.forEach((entity, collider) -> {
            if(collider != null) {
                batch.draw(
                    collider.debugTexture,
                    collider.rect.x,
                    collider.rect.y,
                    collider.rect.width,
                    collider.rect.height
                );
            }
        });
    }
}
