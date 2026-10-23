package com.jgarivera.blitzbit.world.view.components;

import com.badlogic.ashley.core.Component;

public class RenderOrderComponent implements Component {

    public int zIndex;

    public RenderOrderComponent(int zIndex) {
        this.zIndex = zIndex;
    }
}
