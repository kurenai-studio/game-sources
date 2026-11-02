package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.physics.box2d.Body;
import com.ychstudio.ecs.components.RigidBodyComponent;
import com.ychstudio.ecs.components.TransformComponent;

public class PhysicsSystem extends IteratingSystem {

    protected ComponentMapper<TransformComponent> transformM = ComponentMapper.getFor(TransformComponent.class);
    protected ComponentMapper<RigidBodyComponent> rigidBodyM = ComponentMapper.getFor(RigidBodyComponent.class);

    public PhysicsSystem() {
        super(Family.all(TransformComponent.class, RigidBodyComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        Body body = rigidBodyM.get(entity).body;
        TransformComponent transform = transformM.get(entity);

        transform.setPos(body.getPosition());
        transform.rot = body.getAngle();

        if (transform.shouldUpdatezIndexByY) {
            transform.zIndex = transform.y;
        }
    }

}
