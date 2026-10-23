package com.jgarivera.blitzbit.world.player.entities;

import com.badlogic.ashley.core.Entity;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.jgarivera.blitzbit.world.physics.components.PhysicsBodyComponent;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.physics.components.SpeedComponent;
import com.jgarivera.blitzbit.world.physics.components.VelocityComponent;
import com.jgarivera.blitzbit.world.player.components.InputComponent;
import com.jgarivera.blitzbit.world.view.components.AnimatedSpriteComponent;
import com.jgarivera.blitzbit.world.view.components.CameraFollowComponent;
import com.jgarivera.blitzbit.world.view.components.ColorComponent;
import com.jgarivera.blitzbit.world.view.components.RenderOrderComponent;
import com.jgarivera.blitzbit.world.view.components.SizeComponent;

public class Player extends Entity {

    public Player(float spawnX, float spawnY) {
        add(new PositionComponent(spawnX, spawnY));
        add(new VelocityComponent());
        add(new SpeedComponent(5.0f));
        add(new InputComponent());
        add(new SizeComponent(1.0f, 1.0f));
        add(new AnimatedSpriteComponent("player_blink", 1 / 2f));
        add(new RenderOrderComponent(0));
        add(new ColorComponent(Color.GOLDENROD));
        add(new CameraFollowComponent(true));
        add(new PhysicsBodyComponent(BodyDef.BodyType.DynamicBody));
    }
}
