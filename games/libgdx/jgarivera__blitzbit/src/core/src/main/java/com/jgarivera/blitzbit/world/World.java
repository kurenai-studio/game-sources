package com.jgarivera.blitzbit.world;

import com.badlogic.ashley.core.Engine;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.EntityListener;
import com.badlogic.ashley.core.EntitySystem;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.utils.ImmutableArray;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.jgarivera.blitzbit.files.AssetManager;
import com.jgarivera.blitzbit.graphics.Camera;
import com.jgarivera.blitzbit.graphics.Overlay;
import com.jgarivera.blitzbit.input.ActionManager;
import com.jgarivera.blitzbit.input.ToggleManager;
import com.jgarivera.blitzbit.world.npcs.entities.Minion;
import com.jgarivera.blitzbit.world.physics.Physics;
import com.jgarivera.blitzbit.world.physics.components.PhysicsBodyComponent;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.physics.listeners.PhysicsBodyListener;
import com.jgarivera.blitzbit.world.physics.systems.MovementSystem;
import com.jgarivera.blitzbit.world.player.components.InputComponent;
import com.jgarivera.blitzbit.world.player.entities.Player;
import com.jgarivera.blitzbit.world.player.listeners.PlayerActionListener;
import com.jgarivera.blitzbit.world.structures.entities.Flag;
import com.jgarivera.blitzbit.world.view.components.AnimatedSpriteComponent;
import com.jgarivera.blitzbit.world.view.listeners.AnimatedSpriteListener;
import com.jgarivera.blitzbit.world.view.systems.CameraSystem;
import com.jgarivera.blitzbit.world.view.systems.SpriteAnimationSystem;
import com.jgarivera.blitzbit.world.view.systems.SpriteOverlaySystem;
import com.jgarivera.blitzbit.world.view.systems.SpriteSystem;

public class World {
    private final SpriteBatch batch;

    private final Overlay overlay;

    private final float WORLD_HEIGHT = 1280;
    private final float WORLD_WIDTH = 720;

    protected final Physics physics;
    protected final Camera camera;
    protected final ToggleManager toggleManager;
    protected final AssetManager assetManager;
    private final Engine engine;

    public World(Engine engine, Physics physics, Camera camera, ToggleManager toggleManager, AssetManager assetManager) {
        this.engine = engine;
        this.physics = physics;
        this.camera = camera;
        this.toggleManager = toggleManager;
        this.assetManager = assetManager;

        batch = new SpriteBatch();
        overlay = new Overlay(this);

        setupEngine();
        setupActionManager();

        addEntity(new Player(0, 0));
        addEntity(new Minion(5, 5));
        addEntity(new Minion(10, 10));
        addEntity(new Flag(11, 7));
    }

    private void setupEngine() {
        addSystem(new SpriteSystem(assetManager, batch));
        addSystem(new SpriteAnimationSystem(batch));
        addSystem(new SpriteOverlaySystem(this, batch));
        addSystem(new MovementSystem());
        addSystem(new CameraSystem(this));

        addEntityListenerFor(Family.all(PositionComponent.class, PhysicsBodyComponent.class).get(),
                new PhysicsBodyListener(physics));
        addEntityListenerFor(Family.all(AnimatedSpriteComponent.class).get(), new AnimatedSpriteListener(assetManager));
    }

    private void setupActionManager() {
        ActionManager actionManager = new ActionManager();
        actionManager.subscribe(new PlayerActionListener(this));

        Gdx.input.setInputProcessor(actionManager);
    }

    public void show() {

    }

    public void update(float delta) {
        batch.begin();
        physics.update();
        engine.update(delta);
        batch.end();
    }

    public void render(float delta) {
        if (toggleManager.getToggle(ToggleManager.DEBUG_MODE)) {
            physics.drawDebug(camera.combined);
        }

        batch.setProjectionMatrix(camera.combined);
    }

    public void renderOverlay(float delta) {
        overlay.render(delta);
    }

    public void resize(int width, int height) {
        camera.resize(width, height, Camera.VIEWPORT_WIDTH, Camera.VIEWPORT_HEIGHT);
        overlay.resize(width, height);
    }

    public void dispose() {
        batch.dispose();
        physics.dispose();
    }

    /**
     * Assumes the only entity with an InputComponent is the player
     */
    public Entity getPlayer() {
        return getFirstEntityFor(Family.all(InputComponent.class).get());
    }

    public void addEntity(Entity entity) {
        engine.addEntity(entity);
    }

    public void addEntityListenerFor(Family family, EntityListener listener) {
        engine.addEntityListener(family, listener);
    }

    public void addEntityListener(EntityListener listener) {
        engine.addEntityListener(listener);
    }

    public void addSystem(EntitySystem system) {
        engine.addSystem(system);
    }

    public void addSystem(EntitySystem system, int priority) {
        system.priority = priority;
        engine.addSystem(system);
    }

    public ImmutableArray<Entity> getEntitiesFor(Family family) {
        return engine.getEntitiesFor(family);
    }

    public Entity getFirstEntityFor(Family family) {
        return getEntitiesFor(family).first();
    }

    public Physics getPhysics() {
        return physics;
    }

    public Camera getCamera() {
        return camera;
    }

    public ToggleManager getToggleManager() {
        return toggleManager;
    }

    public AssetManager getAssetManager() {
        return assetManager;
    }
}
