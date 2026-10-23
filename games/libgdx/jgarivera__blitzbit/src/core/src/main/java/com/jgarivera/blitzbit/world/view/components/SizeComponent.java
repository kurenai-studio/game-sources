package com.jgarivera.blitzbit.world.view.components;

import com.badlogic.ashley.core.Component;

public class SizeComponent implements Component {
    /**
     * The width in meters.
     */
    public float width;
    /**
     * The height in meters.
     */
    public float height;

    /**
     * Create a size component with specified width and height in meters.
     */
    public SizeComponent(float width, float height) {
        this.width = width;
        this.height = height;
    }
}
