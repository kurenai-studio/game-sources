package com.bossfight.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.bossfight.rendering.RetroTextFactory;
import com.bossfight.rendering.TextureDraw;
import com.bossfight.rendering.TextureLoader;
import com.bossfight.config.Constants;

public class EndScreen extends ScreenAdapter {
    private static final String VICTORY_BACKGROUND_PATH = "sprites/ui/end_victory_background.png";
    private static final String DEFEAT_BACKGROUND_PATH = "sprites/ui/end_defeat_background.png";
    private static final float TEXT_CENTER_X = 380f;
    private static final float TEXT_MAX_WIDTH = 690f;
    private static final float PROMPT_GAP = 14f;
    private static final float VICTORY_TITLE_OFFSET_X = 17f;
    private static final float DEFEAT_TITLE_OFFSET_X = 14f;

    private final GameContext game;
    private final boolean victory;
    private final OrthographicCamera camera;
    private final FitViewport viewport;
    private final RetroTextFactory textFactory;
    private final Texture background;
    private final Texture titleText;
    private final Texture retryKeyText;
    private final Texture retryActionText;
    private final Texture menuKeyText;
    private final Texture menuActionText;

    public EndScreen(GameContext game, boolean victory) {
        this.game = game;
        this.victory = victory;
        camera = new OrthographicCamera();
        viewport = new FitViewport(Constants.WORLD_WIDTH, Constants.WORLD_HEIGHT, camera);
        textFactory = new RetroTextFactory();
        titleText = textFactory.createResultTitle(victory ? "VITÓRIA!" : "DERROTA!", victory);
        retryKeyText = textFactory.createInstructionKey("R");
        retryActionText = textFactory.createInstruction(victory ? "LUTAR OUTRA VEZ" : "REBOBINAR DUELO");
        menuKeyText = textFactory.createInstructionKey("ESC");
        menuActionText = textFactory.createInstruction("VOLTAR AO MENU");
        background = TextureLoader.loadLinear(victory ? VICTORY_BACKGROUND_PATH : DEFEAT_BACKGROUND_PATH);
    }

    @Override
    public void render(float delta) {
        if (Gdx.input.isKeyJustPressed(Input.Keys.R)) {
            game.showBattleScreen();
            return;
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER) || Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            game.showMenuScreen();
            return;
        }

        if (victory) {
            Gdx.gl.glClearColor(0.06f, 0.12f, 0.09f, 1f);
        } else {
            Gdx.gl.glClearColor(0.13f, 0.06f, 0.07f, 1f);
        }
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        viewport.apply();
        game.getBatch().setProjectionMatrix(camera.combined);
        game.getBatch().begin();
        game.getBatch().draw(background, 0f, 0f, Constants.WORLD_WIDTH, Constants.WORLD_HEIGHT);
        float titleOffsetX = victory ? VICTORY_TITLE_OFFSET_X : DEFEAT_TITLE_OFFSET_X;
        TextureDraw.centeredWithin(game.getBatch(), titleText, TEXT_CENTER_X + titleOffsetX, 506f, 0.92f,
                TEXT_MAX_WIDTH);
        drawPrompts();
        game.getBatch().end();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        textFactory.dispose();
        background.dispose();
    }

    private void drawPrompts() {
        float keyScale = 0.72f;
        float actionScale = 0.68f;
        float keyColumnWidth = Math.max(retryKeyText.getWidth(), menuKeyText.getWidth()) * keyScale;
        float actionColumnWidth = Math.max(retryActionText.getWidth(), menuActionText.getWidth()) * actionScale;
        float gap = PROMPT_GAP;
        float totalWidth = keyColumnWidth + gap + actionColumnWidth;

        if (totalWidth > TEXT_MAX_WIDTH) {
            float shrink = TEXT_MAX_WIDTH / totalWidth;
            keyScale *= shrink;
            actionScale *= shrink;
            keyColumnWidth *= shrink;
            actionColumnWidth *= shrink;
            gap *= shrink;
            totalWidth = keyColumnWidth + gap + actionColumnWidth;
        }

        float keyRightX = TEXT_CENTER_X - totalWidth * 0.5f + keyColumnWidth;
        float actionX = keyRightX + gap;
        drawPrompt(retryKeyText, retryActionText, 332f, keyRightX, actionX, keyScale, actionScale);
        drawPrompt(menuKeyText, menuActionText, 282f, keyRightX, actionX, keyScale, actionScale);
    }

    private void drawPrompt(Texture keyTexture, Texture actionTexture, float centerY,
                            float keyRightX, float actionX, float keyScale, float actionScale) {
        float keyWidth = keyTexture.getWidth() * keyScale;
        TextureDraw.atCenterY(game.getBatch(), keyTexture, keyRightX - keyWidth, centerY, keyScale);
        TextureDraw.atCenterY(game.getBatch(), actionTexture, actionX, centerY, actionScale);
    }
}
