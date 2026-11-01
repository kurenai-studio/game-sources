package com.veilfall.game.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputMultiplexer;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.ScreenViewport;
import com.veilfall.game.VeilfallGame;

public abstract class AbstractGameScreen extends ScreenAdapter {
    protected final VeilfallGame game;
    protected final Stage stage;

    protected AbstractGameScreen(VeilfallGame game) {
        this.game = game;
        stage = new Stage(new ScreenViewport());
    }

    @Override
    public void show() {
        Gdx.input.setInputProcessor(new InputMultiplexer(stage, game.getRenderer().getCameraController()));
    }

    @Override
    public void render(float delta) {
        game.getRenderer().render();
        drawStage(delta);
    }

    protected final void drawStage(float delta) {
        stage.act(delta);
        stage.draw();
    }

    protected final void clearDarkBackground(float red, float green, float blue) {
        ScreenUtils.clear(red, green, blue, 1f, true);
    }

    @Override
    public void resize(int width, int height) {
        stage.getViewport().update(width, height, true);
    }

    @Override
    public void hide() {
        if (Gdx.input.getInputProcessor() instanceof InputMultiplexer multiplexer
                && multiplexer.getProcessors().contains(stage, true)) {
            Gdx.input.setInputProcessor(null);
        }
    }

    @Override
    public void dispose() {
        stage.dispose();
    }
}
