package com.jgarivera.blitzbit.world.physics.listeners;

import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.EntityListener;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.PolygonShape;
import com.badlogic.gdx.physics.box2d.World;
import com.jgarivera.blitzbit.world.physics.Physics;
import com.jgarivera.blitzbit.world.physics.components.PhysicsBodyComponent;
import com.jgarivera.blitzbit.world.physics.components.PhysicsComponentMapper;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.view.components.SizeComponent;
import com.jgarivera.blitzbit.world.view.components.ViewComponentMapper;

public class PhysicsBodyListener implements EntityListener {

    private final World physicsWorld;

    public PhysicsBodyListener(Physics physics) {
        physicsWorld = physics.getWorldSimulation();
    }

    @Override
    public void entityAdded(Entity entity) {
        PositionComponent position = PhysicsComponentMapper.POSITION.get(entity);
        PhysicsBodyComponent physicsBody = PhysicsComponentMapper.PHYSICS_BODY.get(entity);
        SizeComponent size = ViewComponentMapper.getSizeComponentOrDefault(entity);

        BodyDef bodyDef = new BodyDef();
        bodyDef.type = physicsBody.bodyType;
        bodyDef.fixedRotation = true;
        bodyDef.position.set(position.x, position.y);

        PolygonShape shape = new PolygonShape();
        shape.setAsBox(size.width / 2.0f, size.height / 2.0f);

        Body body = physicsWorld.createBody(bodyDef);
        body.createFixture(shape, 4.0f);
        shape.dispose();

        physicsBody.body = body;

        Gdx.app.debug("Physics", "Created body for entity");
    }


    @Override
    public void entityRemoved(Entity entity) {
        PhysicsBodyComponent physics = PhysicsComponentMapper.PHYSICS_BODY.get(entity);
        physicsWorld.destroyBody(physics.body);

        Gdx.app.debug("Physics", "Destroyed body for entity");
    }
}
