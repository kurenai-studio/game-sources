package com.elmagica.game;

import com.badlogic.gdx.graphics.Color;

public enum ElementType {
    FIRE("Огонь", new Color(1f, 0.3f, 0.15f, 1f)),
    WATER("Вода", new Color(0.2f, 0.6f, 1f, 1f)),
    EARTH("Земля", new Color(0.7f, 0.4f, 0.2f, 1f)),
    AIR("Воздух", new Color(0.8f, 0.95f, 1f, 1f));

    public final String label;
    public final Color color;

    ElementType(String label, Color color) {
        this.label = label;
        this.color = color;
    }
}
