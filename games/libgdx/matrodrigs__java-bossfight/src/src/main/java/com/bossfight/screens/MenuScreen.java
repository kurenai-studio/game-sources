package com.bossfight.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.bossfight.audio.AudioManager;
import com.bossfight.rendering.RetroTextFactory;
import com.bossfight.rendering.TextureDraw;
import com.bossfight.rendering.TextureLoader;
import com.bossfight.config.Constants;

public class MenuScreen extends ScreenAdapter {
    private static final float MENU_CENTER_X = 638.5f;
    private static final float START_CENTER_Y = 300f;
    private static final float EXIT_CENTER_Y = 176f;
    private static final float TITLE_CENTER_Y = 489f;
    private static final float SUBTITLE_CENTER_Y = 426f;
    private static final float BUTTON_HALF_WIDTH = 221f;
    private static final float TITLE_TEXT_X_OFFSET = -2f;
    private static final float SUBTITLE_TEXT_X_OFFSET = 9f;
    private static final float START_TEXT_X_OFFSET = -3f;
    private static final float EXIT_TEXT_X_OFFSET = -6f;
    private static final float OPTION_TEXT_Y_OFFSET = -7f;
    private static final Color POINTER_SHADOW = new Color(0.03f, 0.02f, 0.01f, 0.45f);
    private static final Color POINTER_INK = new Color(0.05f, 0.035f, 0.02f, 0.96f);
    private static final Color POINTER_GOLD = new Color(0.96f, 0.61f, 0.06f, 1f);
    private static final Color POINTER_GOLD_DARK = new Color(0.58f, 0.27f, 0.03f, 1f);
    private static final Color POINTER_HIGHLIGHT = new Color(1f, 0.84f, 0.33f, 0.92f);

    private final GameContext game;
    private final OrthographicCamera camera;
    private final FitViewport viewport;
    private final RetroTextFactory textFactory;
    private final Texture titleText;
    private final Texture subtitleText;
    private final Texture startText;
    private final Texture startSelectedText;
    private final Texture exitText;
    private final Texture exitSelectedText;
    private final Texture menuBackground;
    private float elapsed;
    private int selectedIndex;

    public MenuScreen(GameContext game) {
        this.game = game;
        camera = new OrthographicCamera();
        viewport = new FitViewport(Constants.WORLD_WIDTH, Constants.WORLD_HEIGHT, camera);
        textFactory = new RetroTextFactory();
        titleText = textFactory.createTitle("Fúria Botânica");
        subtitleText = textFactory.createSubtitle("O Jardim Maldito");
        startText = textFactory.createMenuOption("INICIAR DUELO", false);
        startSelectedText = textFactory.createMenuOption("INICIAR DUELO", true);
        exitText = textFactory.createMenuOption("SAIR", false);
        exitSelectedText = textFactory.createMenuOption("SAIR", true);
        menuBackground = TextureLoader.loadLinear("sprites/ui/menu_background.png");
    }

    @Override
    public void render(float delta) {
        float safeDelta = Math.min(delta, 1f / 30f);
        elapsed += safeDelta;

        if (!handleInput()) {
            return;
        }

        Gdx.gl.glClearColor(0.11f, 0.3f, 0.35f, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        viewport.apply();
        game.getBatch().setProjectionMatrix(camera.combined);
        game.getBatch().begin();
        game.getBatch().draw(menuBackground, 0f, 0f, Constants.WORLD_WIDTH, Constants.WORLD_HEIGHT);
        game.getBatch().end();

        ShapeRenderer shapeRenderer = game.getShapeRenderer();
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapeRenderer.setProjectionMatrix(camera.combined);
        shapeRenderer.begin(com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType.Filled);
        drawOptions();
        shapeRenderer.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);

        game.getBatch().setProjectionMatrix(camera.combined);
        game.getBatch().begin();
        TextureDraw.centered(game.getBatch(), titleText, MENU_CENTER_X + TITLE_TEXT_X_OFFSET,
                TITLE_CENTER_Y + MathUtils.sin(elapsed * 2.2f) * 3f, 0.72f);
        TextureDraw.centered(game.getBatch(), subtitleText, MENU_CENTER_X + SUBTITLE_TEXT_X_OFFSET,
                SUBTITLE_CENTER_Y, 0.72f);
        drawOptionText(0, START_CENTER_Y);
        drawOptionText(1, EXIT_CENTER_Y);
        game.getBatch().end();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        textFactory.dispose();
        menuBackground.dispose();
    }

    private boolean handleInput() {
        if (game.isIrisTransitionActive()) {
            return true;
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.UP) || Gdx.input.isKeyJustPressed(Input.Keys.W)
                || Gdx.input.isKeyJustPressed(Input.Keys.DOWN) || Gdx.input.isKeyJustPressed(Input.Keys.S)) {
            selectedIndex = 1 - selectedIndex;
            game.getAudioManager().playCue(AudioManager.Cue.MENU_MOVE);
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER) || Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
            game.getAudioManager().playCue(AudioManager.Cue.MENU_CONFIRM);
            if (selectedIndex == 0) {
                game.showBattleScreen();
            } else {
                Gdx.app.exit();
                return false;
            }
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            game.getAudioManager().playCue(AudioManager.Cue.MENU_BACK);
            Gdx.app.exit();
            return false;
        }

        return true;
    }

    private void drawOptions() {
        drawSelectionMarkers(selectedIndex == 0 ? START_CENTER_Y : EXIT_CENTER_Y);
    }

    private void drawSelectionMarkers(float centerY) {
        ShapeRenderer shapeRenderer = game.getShapeRenderer();
        float wobble = MathUtils.sin(elapsed * 10f) * 5f;
        float leftX = MENU_CENTER_X - BUTTON_HALF_WIDTH - 38f - wobble;
        float rightX = MENU_CENTER_X + BUTTON_HALF_WIDTH + 38f + wobble;

        drawPointer(shapeRenderer, leftX, centerY, true);
        drawPointer(shapeRenderer, rightX, centerY, false);
    }

    private void drawPointer(ShapeRenderer shapeRenderer, float x, float y, boolean pointsRight) {
        float direction = pointsRight ? 1f : -1f;
        float scale = 1f + MathUtils.sin(elapsed * 15f) * 0.04f;

        drawPointerSilhouette(shapeRenderer, x + direction * 3f, y - 3f, direction, scale, POINTER_SHADOW);
        drawPointerSilhouette(shapeRenderer, x, y, direction, scale, POINTER_INK);
        drawPointerFill(shapeRenderer, x, y, direction, scale);
    }

    private void drawPointerSilhouette(ShapeRenderer shapeRenderer, float x, float y, float direction, float scale,
            Color color) {
        float shoulderX = x - direction * 30f * scale;
        float rootX = x - direction * 39f * scale;
        float outerX = rootX - direction * 22f * scale;
        float headHeight = 23f * scale;

        shapeRenderer.setColor(color);
        shapeRenderer.triangle(x + direction * 3f * scale, y,
                shoulderX, y + headHeight,
                shoulderX, y - headHeight);
        shapeRenderer.rectLine(shoulderX, y, rootX, y, 16f * scale);
        drawFleurPetal(shapeRenderer, rootX, y, outerX, y, 8f * scale);
        drawFleurPetal(shapeRenderer, rootX, y + 3f * scale,
                rootX - direction * 18f * scale, y + 17f * scale, 6f * scale);
        drawFleurPetal(shapeRenderer, rootX, y - 3f * scale,
                rootX - direction * 18f * scale, y - 17f * scale, 6f * scale);
    }

    private void drawFleurPetal(ShapeRenderer shapeRenderer, float rootX, float rootY, float tipX, float tipY,
            float radius) {
        shapeRenderer.triangle(rootX, rootY,
                tipX, tipY + radius,
                tipX, tipY - radius);
        shapeRenderer.circle(tipX, tipY, radius * 0.72f);
    }

    private void drawPointerFill(ShapeRenderer shapeRenderer, float x, float y, float direction, float scale) {
        float shoulderX = x - direction * 27f * scale;
        float rootX = x - direction * 39f * scale;

        shapeRenderer.setColor(POINTER_GOLD_DARK);
        shapeRenderer.triangle(x - direction * 2f * scale, y - 2f * scale,
                shoulderX, y - 16f * scale,
                shoulderX, y - 4f * scale);

        shapeRenderer.setColor(POINTER_GOLD);
        shapeRenderer.triangle(x - direction * 2f * scale, y,
                shoulderX, y + 16f * scale,
                shoulderX, y - 16f * scale);
        shapeRenderer.rectLine(shoulderX, y, rootX, y, 8f * scale);

        shapeRenderer.setColor(POINTER_HIGHLIGHT);
        shapeRenderer.triangle(x - direction * 8f * scale, y + 3f * scale,
                x - direction * 23f * scale, y + 11f * scale,
                x - direction * 24f * scale, y + 6f * scale);
    }

    private void drawOptionText(int index, float centerY) {
        boolean selected = selectedIndex == index;
        Texture texture;
        if (index == 0) {
            texture = selected ? startSelectedText : startText;
        } else {
            texture = selected ? exitSelectedText : exitText;
        }
        float baseXOffset = index == 0 ? START_TEXT_X_OFFSET : EXIT_TEXT_X_OFFSET;
        float xOffset = baseXOffset + (selected ? MathUtils.sin(elapsed * 10f) * 4f : 0f);
        TextureDraw.centered(game.getBatch(), texture, MENU_CENTER_X + xOffset, centerY + OPTION_TEXT_Y_OFFSET, 0.64f);
    }
}
