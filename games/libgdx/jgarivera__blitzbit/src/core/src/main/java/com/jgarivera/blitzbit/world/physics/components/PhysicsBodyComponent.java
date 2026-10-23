package com.jgarivera.blitzbit.world.physics.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;

public class PhysicsBodyComponent implements Component {
    public Body body;

    public BodyDef.BodyType bodyType;

    public PhysicsBodyComponent(BodyDef.BodyType bodyType) {
        this.bodyType = bodyType;
    }

    public PhysicsBodyComponent(Body body, BodyDef.BodyType bodyType) {
        this.body = body;
        this.bodyType = bodyType;
    }
}
