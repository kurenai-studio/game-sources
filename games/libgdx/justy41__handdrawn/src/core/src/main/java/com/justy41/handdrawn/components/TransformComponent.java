package com.justy41.handdrawn.components;

import com.badlogic.gdx.math.Vector2;

public class TransformComponent extends Component {
    public Vector2 position, scale;
    public float rotation;

    public TransformComponent() {
        position = new Vector2(0, 0);
        scale = new Vector2(1, 1);
        rotation = 0;
    }

    public TransformComponent(float x, float y) {
        position = new Vector2(x, y);
        scale = new Vector2(1, 1);
        rotation = 0;
    }

    public TransformComponent(float x, float y, float sizeX, float sizeY, float rotation) {
        position = new Vector2(x, y);
        scale = new Vector2(sizeX, sizeY);
        this.rotation = rotation;
    }
}
