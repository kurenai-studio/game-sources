package com.jgarivera.blitzbit.world.structures.entities;

import com.badlogic.ashley.core.Entity;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.jgarivera.blitzbit.world.physics.components.PhysicsBodyComponent;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.physics.components.VelocityComponent;
import com.jgarivera.blitzbit.world.view.components.RenderOrderComponent;
import com.jgarivera.blitzbit.world.view.components.SizeComponent;
import com.jgarivera.blitzbit.world.view.components.SpriteComponent;

public class Flag extends Entity {

    public Flag(float spawnX, float spawnY) {
        add(new PositionComponent(spawnX, spawnY));
        add(new VelocityComponent());
        add(new SpriteComponent("flag.png"));
        add(new RenderOrderComponent(1));
        add(new SizeComponent(3.0f, 3.0f));
        add(new PhysicsBodyComponent(BodyDef.BodyType.StaticBody));
    }
}
