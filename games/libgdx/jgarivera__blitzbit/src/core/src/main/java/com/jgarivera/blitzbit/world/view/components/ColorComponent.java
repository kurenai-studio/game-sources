package com.jgarivera.blitzbit.world.view.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.graphics.Color;

public class ColorComponent implements Component {
    public Color color;

    public ColorComponent(Color color) {
        this.color = color;
    }
}
