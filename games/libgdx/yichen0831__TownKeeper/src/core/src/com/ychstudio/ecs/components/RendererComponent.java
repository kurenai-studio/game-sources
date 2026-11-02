package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

public class RendererComponent implements Component {

    public Sprite sprite;

    public RendererComponent(TextureRegion textureRegion, float width, float height) {
        sprite = new Sprite(textureRegion);
        sprite.setSize(width, height);
    }

    public float getWidth() {
        return sprite.getWidth();
    }

    public float getHeight() {
        return sprite.getHeight();
    }
}
