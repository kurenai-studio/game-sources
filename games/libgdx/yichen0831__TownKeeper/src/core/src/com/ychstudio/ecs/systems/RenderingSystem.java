package com.ychstudio.ecs.systems;

import java.util.Comparator;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.SortedIteratingSystem;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.ychstudio.ecs.components.RendererComponent;
import com.ychstudio.ecs.components.TransformComponent;

public class RenderingSystem extends SortedIteratingSystem {

    protected static ComponentMapper<TransformComponent> transformM = ComponentMapper.getFor(TransformComponent.class);
    protected ComponentMapper<RendererComponent> rendererM = ComponentMapper.getFor(RendererComponent.class);

    private SpriteBatch batch;

    public RenderingSystem(SpriteBatch batch) {
        super(Family.all(TransformComponent.class, RendererComponent.class).get(), new Comparator<Entity>() {

            @Override
            public int compare(Entity e1, Entity e2) {
                TransformComponent t1 = transformM.get(e1);
                TransformComponent t2 = transformM.get(e2);

                return (int) Math.signum(t2.zIndex - t1.zIndex);
            }
        });
        this.batch = batch;
    }

    @Override
    public void update(float deltaTime) {
        forceSort(); // need forceSort, otherwise the sorting only happens when
                     // the EntitySystem is updated
        batch.begin();
        super.update(deltaTime);
        batch.end();
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        TransformComponent transform = transformM.get(entity);
        RendererComponent renderer = rendererM.get(entity);
        renderer.sprite.setPosition(transform.x - renderer.getWidth() / 2, transform.y - renderer.getHeight() / 2);
        renderer.sprite.setRotation(transform.rot);
        renderer.sprite.setScale(transform.sclX, transform.sclY);
        renderer.sprite.draw(batch);
    }

}
