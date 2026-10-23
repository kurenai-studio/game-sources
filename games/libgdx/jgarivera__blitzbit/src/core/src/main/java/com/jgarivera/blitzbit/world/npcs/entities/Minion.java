package com.jgarivera.blitzbit.world.npcs.entities;

import com.badlogic.ashley.core.Entity;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.jgarivera.blitzbit.world.physics.components.PhysicsBodyComponent;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.physics.components.VelocityComponent;
import com.jgarivera.blitzbit.world.view.components.ColorComponent;
import com.jgarivera.blitzbit.world.view.components.RenderOrderComponent;
import com.jgarivera.blitzbit.world.view.components.SizeComponent;
import com.jgarivera.blitzbit.world.view.components.SpriteComponent;

public class Minion extends Entity {

    public Minion(float spawnX, float spawnY) {
        add(new PositionComponent(spawnX, spawnY));
        add(new VelocityComponent());
        add(new SpriteComponent("minion.png"));
        add(new RenderOrderComponent(-1));
        add(new ColorComponent(Color.FIREBRICK));
        add(new SizeComponent(1.0f, 1.0f));
        add(new PhysicsBodyComponent(BodyDef.BodyType.DynamicBody));
    }
}
