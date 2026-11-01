package com.github.br.libgdx.jam38.structure.screen;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.profiling.GLProfiler;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.github.br.libgdx.jam38.structure.GameSettings;
import com.github.br.libgdx.jam38.structure.ui.ActorFactory;
import com.github.br.libgdx.jam38.structure.ui.CustomOrthogonalTiledMapRenderer;

public abstract class AbstractTiledMapUiScreen extends AbstractGameScreen {

    private final String tiledMapPath;
    private final String pathToSkin;

    protected TiledMap tiledMap;
    protected CustomOrthogonalTiledMapRenderer renderer;

    protected OrthographicCamera camera;
    protected Viewport viewport;

    protected ActorFactory actorFactory;

    private boolean isGlProfileActive;
    private GLProfiler profiler;

    public AbstractTiledMapUiScreen(String tiledMapPath, String pathToSkin, boolean isGlProfileActive) {
        this.tiledMapPath = tiledMapPath;
        this.pathToSkin = pathToSkin;
        this.isGlProfileActive = isGlProfileActive;
    }

    @Override
    public void show() {
        if (isGlProfileActive) {
            profiler = new GLProfiler(Gdx.graphics);
            profiler.enable();
        }
        AssetManager assetManager = getGameManager().assetManager;
        tiledMap = assetManager.get(tiledMapPath);

        GameSettings gameSettings = getGameManager().gameSettings;
        camera = new OrthographicCamera();
        viewport = new ExtendViewport(
            gameSettings.getVirtualScreenWidth(),
            gameSettings.getVirtualScreenHeight(),
            camera
        );

        Skin gameSkin = assetManager.get(pathToSkin);
        actorFactory = new ActorFactory(gameSkin, assetManager);
        renderer = new CustomOrthogonalTiledMapRenderer(actorFactory, viewport, tiledMap, 1f);

        afterShow(tiledMap, renderer, viewport, actorFactory);
    }

    protected abstract void afterShow(
        TiledMap tiledMap,
        CustomOrthogonalTiledMapRenderer renderer,
        Viewport viewport,
        ActorFactory actorFactory
    );

    @Override
    public void render(float delta) {
        update(delta);

        Gdx.gl.glClearColor(1, 1, 1, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        camera.update();
        renderer.setView(camera);
        renderer.render();

        if (isGlProfileActive) {
            // Вывод информации (например, в консоль или на экран через Label)
            String simpleName = this.getClass().getSimpleName();
            Gdx.app.log(simpleName, "Draw Calls: " + profiler.getDrawCalls());
            Gdx.app.log(simpleName, "Texture Bindings: " + profiler.getTextureBindings());
            Gdx.app.log(simpleName, "Shader Switches: " + profiler.getShaderSwitches());
            Gdx.app.log(simpleName, "Vertices: " + profiler.getVertexCount().total);
            Gdx.app.log(simpleName, "\n");

            // Обязательно сбрасываем счетчик в конце кадра!
            profiler.reset();
        }
    }

    protected abstract void update(float delta);

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
        renderer.resize(width, height);
    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {

    }

    @Override
    public void hide() {

    }

    @Override
    public void dispose() {

    }

}
