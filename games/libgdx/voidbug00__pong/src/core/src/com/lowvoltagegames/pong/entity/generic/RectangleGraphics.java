package com.lowvoltagegames.pong.entity.generic;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.GraphicsComponent;

/**
 * Graphics components that draws rectangular objects
 */
public class RectangleGraphics implements GraphicsComponent {
    /**
     * Render the object as a rectangle
     * @param obj GameObject to be rendered
     * @param renderer Current renderer being used by screen. Objects can only be rendered using a ShapeRenderer
     */
    @Override
    public void render(GameObject obj, ShapeRenderer renderer) {
        renderer.rect(obj.x, obj.y, obj.width, obj.height);
    }
}
