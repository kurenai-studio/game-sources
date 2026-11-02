package com.lowvoltagegames.pong.entity;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * Component representing how an object should be rendered
 */
public interface GraphicsComponent {
    /**
     * Render the object each tick
     * @param obj GameObject to be rendered
     * @param renderer Current renderer being used by screen. Objects can only be rendered using a ShapeRenderer
     */
    void render(GameObject obj, ShapeRenderer renderer);
}
