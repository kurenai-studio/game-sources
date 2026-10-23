package com.jgarivera.blitzbit.world.physics.systems;

import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.jgarivera.blitzbit.world.physics.components.PhysicsBodyComponent;
import com.jgarivera.blitzbit.world.physics.components.PhysicsComponentMapper;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.physics.components.VelocityComponent;

public class MovementSystem extends IteratingSystem {

    public MovementSystem() {
        super(Family.all(PositionComponent.class, VelocityComponent.class, PhysicsBodyComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        PositionComponent position = PhysicsComponentMapper.POSITION.get(entity);
        VelocityComponent velocity = PhysicsComponentMapper.VELOCITY.get(entity);
        PhysicsBodyComponent physics = PhysicsComponentMapper.PHYSICS_BODY.get(entity);

        Body body = physics.body;
        Vector2 bodyPosition = body.getPosition();

        position.x = bodyPosition.x;
        position.y = bodyPosition.y;

        body.setLinearVelocity(velocity.x, velocity.y);
    }
}
