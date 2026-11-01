package com.github.br.libgdx.jam38.game.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.github.br.libgdx.jam38.structure.GameSettings;
import com.github.br.libgdx.jam38.structure.screen.AbstractGameScreen;

public class EndScreen extends AbstractGameScreen {

    private SpriteBatch spriteBatch;
    private Stage stage;
    private Viewport viewport;
    private OrthographicCamera camera;

    private Label endLabel;

    @Override
    public void show() {
        GameSettings gameSettings = getGameManager().gameSettings;

        camera = new OrthographicCamera();
        viewport = new ExtendViewport(
            gameSettings.getVirtualScreenWidth(),
            gameSettings.getVirtualScreenHeight(),
            camera
        );
        viewport.apply(true);

        spriteBatch = new SpriteBatch();
        stage = new Stage(viewport, spriteBatch);

        // 1. Создаем дефолтный шрифт LibGDX (вы можете заменить его на свой .fnt)
        BitmapFont font = new BitmapFont();
        font.getData().setScale(3.0f); // Увеличиваем размер надписи в 3 раза

        // 2. Создаем стиль для надписи
        Label.LabelStyle labelStyle = new Label.LabelStyle(font, Color.WHITE);

        // 3. Создаем саму надпись THE END
        endLabel = new Label("THE END", labelStyle);

        // Добавляем надпись на Stage
        stage.addActor(endLabel);

        // Разрешаем Stage обрабатывать ввод (если потом добавите кнопки)
        Gdx.input.setInputProcessor(stage);
    }

    @Override
    public void render(float delta) {
        // Очищаем экран черным цветом
        Gdx.gl.glClearColor(0, 0, 0, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // Обновляем камеру и вьюпорт перед отрисовкой
        camera.update();
        viewport.apply(false); // false, чтобы не сбрасывать позицию камеры ручным центрированием

        // Принудительно держим камеру по центру актуального мира
        camera.position.set(viewport.getWorldWidth() / 2f, viewport.getWorldHeight() / 2f, 0);

        spriteBatch.setProjectionMatrix(camera.combined);

        stage.act(delta);
        stage.draw();
    }

    @Override
    public void resize(int width, int height) {
        // Обновляем размеры вьюпорта сцены без автоматического сброса камеры
        viewport.update(width, height, false);

        // Вычисляем точный центр расширенного игрового мира
        float centerX = viewport.getWorldWidth() / 2f;
        float centerY = viewport.getWorldHeight() / 2f;

        // Центрируем надпись, вычитая половину её собственных размеров
        endLabel.setPosition(
            centerX - endLabel.getGlyphLayout().width / 2f,
            centerY - endLabel.getGlyphLayout().height / 2f
        );
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
        // Освобождаем ресурсы
        if (spriteBatch != null) spriteBatch.dispose();
        if (stage != null) stage.dispose();
        if (endLabel != null && endLabel.getStyle().font != null) {
            endLabel.getStyle().font.dispose();
        }
    }
}
