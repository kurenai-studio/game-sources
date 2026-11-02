package com.lowvoltagegames.pong.entity;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.lowvoltagegames.pong.GameScreen;

/**
 * Represent each entity in the game using components
 */
public abstract class GameObject {
    /** Object's position in 2d space */
    public float x, y;
    /** Object's dimensions **/
    public float width, height;
    /** Object's current speed **/
    public float velocity;

    private final InputComponent input;
    private final PhysicsComponent physics;
    private final GraphicsComponent graphics;

    /**
     * Creates a new ball using given components
     * @param input InputComponent to be used for this object
     * @param physics PhysicsComponent to be used for this object
     * @param graphics GraphicsComponent to be used for this object
     */
    public GameObject(InputComponent input, PhysicsComponent physics, GraphicsComponent graphics) {
        this.input = input;
        this.physics = physics;
        this.graphics = graphics;
    }

    /**
     * Update object each tick, before rendering
     * @see InputComponent#update(GameObject)
     * @see PhysicsComponent#update(GameObject, GameScreen, float)
     * @param screen Current screen being updated
     * @param delta Time since last update in millis
     */
    public void update(GameScreen screen, float delta) {
        input.update(this);
        physics.update(this, screen, delta);
    }

    /**
     * Render object to screen using shape rendering
     * @see GraphicsComponent#render(GameObject, ShapeRenderer)
     * @param renderer Current ShapeRenderer
     */
    public void render(ShapeRenderer renderer) {
        graphics.render(this, renderer);
    }

    /**
     * Handle collision with another GameObject
     * @param obj GameObject this object has collided with
     */
    public void collision(GameObject obj) {
        physics.collision(this, obj);
    }
}
