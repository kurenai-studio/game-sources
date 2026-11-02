package com.ychstudio.screens;

import com.badlogic.ashley.core.Engine;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.physics.box2d.Box2DDebugRenderer;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.ychstudio.TownKeeper;
import com.ychstudio.ai.AStarPathFinding;
import com.ychstudio.builders.WorldBuilder;
import com.ychstudio.ecs.systems.AnimalSystem;
import com.ychstudio.ecs.systems.AnimationSystem;
import com.ychstudio.ecs.systems.FarmSystem;
import com.ychstudio.ecs.systems.HunterSystem;
import com.ychstudio.ecs.systems.LifeSystem;
import com.ychstudio.ecs.systems.NPC_ItemSystem;
import com.ychstudio.ecs.systems.PhysicsSystem;
import com.ychstudio.ecs.systems.PlayerSystem;
import com.ychstudio.ecs.systems.RenderingSystem;
import com.ychstudio.ecs.systems.StateSystem;
import com.ychstudio.ecs.systems.TentSystem;
import com.ychstudio.ecs.systems.VillagerSystem;
import com.ychstudio.gamesys.GameManager;
import com.ychstudio.gamesys.WorldContactListener;

public class PlayScreen implements Screen {

    private final TownKeeper game;
    private final SpriteBatch batch;

    private final float VIEW_WIDTH = 16f;
    private final float VIEW_HEIGHT = 12f;

    private World world;
    private Engine engine;

    private FitViewport viewport;
    private OrthographicCamera camera;

    private Box2DDebugRenderer box2dDebugRenderer;
    private boolean showBox2DDebugRenderer;

    private TiledMap tiledMap;
    private OrthogonalTiledMapRenderer tiledMapRenderer;

    private final Vector3 tmpVector3 = new Vector3();

    public PlayScreen(TownKeeper game) {
        this.game = game;
        this.batch = game.getBatch();
    }

    @Override
    public void show() {

        camera = new OrthographicCamera();
        viewport = new FitViewport(VIEW_WIDTH, VIEW_HEIGHT, camera);

        world = new World(new Vector2(), true);
        world.setContactListener(new WorldContactListener());
        
        engine = new Engine();

        engine.addSystem(new PlayerSystem());
        engine.addSystem(new VillagerSystem());
        engine.addSystem(new HunterSystem());
        engine.addSystem(new AnimalSystem());
        engine.addSystem(new FarmSystem(world));
        engine.addSystem(new LifeSystem());
        engine.addSystem(new NPC_ItemSystem());
        engine.addSystem(new TentSystem(world));
        engine.addSystem(new PhysicsSystem());
        engine.addSystem(new StateSystem());
        engine.addSystem(new AnimationSystem());
        engine.addSystem(new RenderingSystem(batch));

        box2dDebugRenderer = new Box2DDebugRenderer();
        showBox2DDebugRenderer = true;

        WorldBuilder worldBuilder = WorldBuilder.getInstance(world, engine);
        tiledMap = worldBuilder.loadTiledMap("map1.tmx");
        tiledMapRenderer = new OrthogonalTiledMapRenderer(tiledMap, 1 / GameManager.PPM, batch);

        AStarPathFinding aStarPathFinding = AStarPathFinding.getInstance();
        aStarPathFinding.init(world, worldBuilder.getMapWidth(), worldBuilder.getMapHeight());
        camera.position.set(new Vector3(GameManager.playerCurrentPos, 0));
    }

    @Override
    public void render(float delta) {
        handleInput();

        Gdx.gl.glClearColor(0f, 0f, 0f, 1.0f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // update camera
        updateCamera();

        batch.setProjectionMatrix(camera.combined);
        tiledMapRenderer.setView(camera);
        tiledMapRenderer.render();

        world.step(Math.min(delta, 1 / 60f), 8, 3);
        engine.update(delta);

        if (showBox2DDebugRenderer) {
            box2dDebugRenderer.render(world, camera.combined);
        }
    }

    private void updateCamera() {
        float targetX = MathUtils.clamp(GameManager.playerCurrentPos.x, GameManager.moveBound.x + VIEW_WIDTH / 2f,
                GameManager.moveBound.width - VIEW_WIDTH / 2f);
        float targetY = MathUtils.clamp(GameManager.playerCurrentPos.y, GameManager.moveBound.y + VIEW_HEIGHT / 2f,
                GameManager.moveBound.height - VIEW_HEIGHT / 2f);
        camera.position.lerp(tmpVector3.set(targetX, targetY, 0), 0.1f);
        camera.update();
    }

    private void handleInput() {

        if (Gdx.input.isKeyJustPressed(Input.Keys.B)) {
            showBox2DDebugRenderer = !showBox2DDebugRenderer;
        }

    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height);
    }

    @Override
    public void pause() {
    }

    @Override
    public void resume() {
    }

    @Override
    public void hide() {
        dispose();
    }

    @Override
    public void dispose() {
        world.dispose();
        tiledMapRenderer.dispose();
        box2dDebugRenderer.dispose();
    }

}
