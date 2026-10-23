package com.jgarivera.blitzbit.world.view.components;

import com.badlogic.ashley.core.Component;

public class CameraFollowComponent implements Component {
    public boolean shouldFollow = false;

    public CameraFollowComponent() {
    }

    public CameraFollowComponent(boolean shouldFollow) {
        this.shouldFollow = shouldFollow;
    }
}
