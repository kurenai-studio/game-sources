package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.physics.box2d.Body;

public class RigidBodyComponent implements Component {

    public Body body;

    public RigidBodyComponent(Body body) {
        this.body = body;
    }
}
