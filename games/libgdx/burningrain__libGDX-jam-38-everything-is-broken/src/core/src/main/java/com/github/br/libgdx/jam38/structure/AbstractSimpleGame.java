package com.github.br.libgdx.jam38.structure;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.assets.loaders.resolvers.InternalFileHandleResolver;
import com.github.br.libgdx.jam38.structure.audio.AudioAssetManager;
import com.github.br.libgdx.jam38.structure.screen.loading.LoadingScreen;
import com.github.br.libgdx.jam38.structure.screen.loading.SimpleProgressBarImpl;
import com.github.br.libgdx.jam38.structure.screen.statemachine.GameScreenState;


public abstract class AbstractSimpleGame<U extends UserFactory> extends ApplicationAdapter {

    private GameSettings gameSettings;
    private AudioSettings audioSettings;
    private SimpleUtils simpleUtils;
    private AssetManager assetManager;
    private AudioAssetManager audioAssetManager;
    private GameManager<U> gameManager;

    @Override
    public void create() {
        GameSettings.Builder builder = GameSettings.builder();
        fillGameSettings(builder);
        gameSettings = builder.build();
        audioSettings = createAudioSettings();
        simpleUtils = new SimpleUtils(gameSettings);

        InternalFileHandleResolver fileHandleResolver = new InternalFileHandleResolver();
        assetManager = new AssetManager();
        audioAssetManager = new AudioAssetManager(assetManager, audioSettings);
        initLoaders(assetManager, fileHandleResolver);

        gameManager = new GameManager<U>();
        gameManager.init(
                gameSettings,
                audioSettings,
                simpleUtils,
                assetManager,
                audioAssetManager,
                createLoadingScreen(),
                createStartState(),
                createUserFactory()
        );

        boolean npotSupported = Gdx.graphics.supportsExtension("GL_OES_texture_npot")
            || Gdx.graphics.supportsExtension("GL_ARB_texture_non_power_of_two");
        Gdx.app.debug("App", "isNpotSupported: " + npotSupported);
    }

    protected abstract U createUserFactory();

    protected LoadingScreen createLoadingScreen() {
        return new LoadingScreen(
                new SimpleProgressBarImpl(
                        gameSettings.getProgressBarWidth(),
                        gameSettings.getProgressBarHeight(),
                        (gameSettings.getVirtualScreenWidth() - gameSettings.getProgressBarWidth()) / 2,
                        (gameSettings.getVirtualScreenHeight() - gameSettings.getProgressBarHeight()) / 2
                ),
                gameSettings.getVirtualScreenWidth(),
                gameSettings.getVirtualScreenHeight()
        );
    }

    protected abstract GameScreenState createStartState();

    protected abstract void initLoaders(AssetManager assetManager, InternalFileHandleResolver fileHandleResolver);

    protected abstract void fillGameSettings(GameSettings.Builder builder);

    private AudioSettings createAudioSettings() {
        return new AudioSettings();
    }

    @Override
    public void render() {
        gameManager.screenStateManager.render(Gdx.graphics.getDeltaTime());
    }

    @Override
    public void resize(int width, int height) {
        gameManager.screenStateManager.resize(width, height);
    }

    @Override
    public void pause() {
        gameManager.screenStateManager.pause();
    }

    @Override
    public void resume() {
        gameManager.screenStateManager.resume();
    }

    @Override
    public void dispose() {
        gameManager.screenStateManager.dispose();
        assetManager.dispose();
    }

}
