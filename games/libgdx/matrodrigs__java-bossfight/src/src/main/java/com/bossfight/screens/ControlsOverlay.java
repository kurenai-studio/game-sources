package com.bossfight.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;
import com.bossfight.rendering.RetroTextFactory;
import com.bossfight.rendering.TextureDraw;

final class ControlsOverlay {
    private static final String[] KEY_LABELS = {"A", "D", "ESPAÇO", "SHIFT"};
    private static final String[] ACTIONS = {"MOVER", "PULAR", "DASH", "ATIRAR", "ESPECIAL"};
    private static final float DISPLAY_DURATION = 5.4f;
    private static final float FADE_IN_DURATION = 0.32f;
    private static final float FADE_OUT_START = 4.25f;
    private static final float FADE_OUT_DURATION = DISPLAY_DURATION - FADE_OUT_START;
    private static final float PANEL_WIDTH = 900f;
    private static final float PANEL_HEIGHT = 118f;
    private static final float PANEL_X = (Constants.WORLD_WIDTH - PANEL_WIDTH) * 0.5f;
    private static final float PANEL_Y = 558f;
    private static final float FIRST_CONTROL_X = PANEL_X + 110f;
    private static final float CONTROL_GAP = 170f;
    private static final float ICON_CENTER_Y = PANEL_Y + 72f;
    private static final float ACTION_CENTER_Y = PANEL_Y + 28f;
    private static final float RIBBON_WIDTH = 218f;
    private static final float RIBBON_HEIGHT = 44f;

    private static boolean shownThisSession;

    private final Texture titleText;
    private final Texture[] keyTexts = new Texture[KEY_LABELS.length];
    private final Texture[] actionTexts = new Texture[ACTIONS.length];
    private final Texture holdText;
    private final Texture clickText;
    private float displayTimer = DISPLAY_DURATION;

    ControlsOverlay(RetroTextFactory textFactory) {
        titleText = textFactory.createMenuOption("COMANDOS", true);
        for (int i = 0; i < KEY_LABELS.length; i++) {
            keyTexts[i] = textFactory.createInstructionKey(KEY_LABELS[i]);
        }
        for (int i = 0; i < ACTIONS.length; i++) {
            actionTexts[i] = textFactory.createInstruction(ACTIONS[i]);
        }
        holdText = textFactory.createInstruction("SEGURE");
        clickText = textFactory.createInstruction("CLIQUE");
    }

    void showOnce() {
        if (shownThisSession) {
            return;
        }
        shownThisSession = true;
        displayTimer = 0f;
    }

    void update(float delta) {
        displayTimer = Math.min(DISPLAY_DURATION, displayTimer + delta);
    }

    void render(SpriteBatch batch, ShapeRenderer shapeRenderer, OrthographicCamera camera, float gameElapsed) {
        float alpha = alpha();
        if (alpha <= 0f) {
            return;
        }

        float entrance = smoothStep(MathUtils.clamp(displayTimer / FADE_IN_DURATION, 0f, 1f));
        float yOffset = (1f - entrance) * 18f + MathUtils.sin(gameElapsed * 2.8f) * 1.2f;
        float panelY = PANEL_Y + yOffset;

        drawCard(shapeRenderer, camera, panelY, alpha);
        drawText(batch, camera, panelY, alpha);
    }

    private void drawCard(ShapeRenderer shapeRenderer, OrthographicCamera camera, float panelY, float alpha) {
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapeRenderer.setProjectionMatrix(camera.combined);
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);

        roundedRect(shapeRenderer, PANEL_X + 6f, panelY - 6f, PANEL_WIDTH, PANEL_HEIGHT, 12f,
                0.025f, 0.018f, 0.012f, alpha * 0.34f);
        roundedRect(shapeRenderer, PANEL_X, panelY, PANEL_WIDTH, PANEL_HEIGHT, 12f,
                0.28f, 0.085f, 0.045f, alpha * 0.97f);
        roundedRect(shapeRenderer, PANEL_X + 6f, panelY + 6f, PANEL_WIDTH - 12f, PANEL_HEIGHT - 12f, 8f,
                0.965f, 0.88f, 0.69f, alpha * 0.98f);

        shapeRenderer.setColor(0.43f, 0.14f, 0.075f, alpha * 0.55f);
        shapeRenderer.rect(PANEL_X + 18f, panelY + 13f, PANEL_WIDTH - 36f, 2f);
        shapeRenderer.rect(PANEL_X + 18f, panelY + PANEL_HEIGHT - 15f, PANEL_WIDTH - 36f, 2f);

        drawKeyboardControls(shapeRenderer, panelY, alpha);
        drawMouse(shapeRenderer, controlX(3), ICON_CENTER_Y + panelY - PANEL_Y, true, alpha);
        drawMouse(shapeRenderer, controlX(4), ICON_CENTER_Y + panelY - PANEL_Y, false, alpha);
        drawTitleRibbon(shapeRenderer, panelY, alpha);

        shapeRenderer.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
    }

    private void drawKeyboardControls(ShapeRenderer shapeRenderer, float panelY, float alpha) {
        float iconY = ICON_CENTER_Y + panelY - PANEL_Y;
        drawKeyCap(shapeRenderer, controlX(0) - 26f, iconY, 44f, alpha);
        drawKeyCap(shapeRenderer, controlX(0) + 26f, iconY, 44f, alpha);
        drawKeyCap(shapeRenderer, controlX(1), iconY, 112f, alpha);
        drawKeyCap(shapeRenderer, controlX(2), iconY, 102f, alpha);
    }

    private void drawKeyCap(ShapeRenderer shapeRenderer, float centerX, float centerY, float width, float alpha) {
        float height = 38f;
        float x = centerX - width * 0.5f;
        float y = centerY - height * 0.5f;
        roundedRect(shapeRenderer, x + 2f, y - 3f, width, height, 7f,
                0.16f, 0.05f, 0.03f, alpha * 0.4f);
        roundedRect(shapeRenderer, x, y, width, height, 7f,
                0.38f, 0.115f, 0.055f, alpha * 0.96f);
        roundedRect(shapeRenderer, x + 4f, y + 5f, width - 8f, height - 10f, 4f,
                0.98f, 0.79f, 0.29f, alpha * 0.94f);
    }

    private void drawMouse(ShapeRenderer shapeRenderer, float centerX, float centerY, boolean leftButton,
                           float alpha) {
        float width = 50f;
        float height = 56f;
        float x = centerX - width * 0.5f;
        float y = centerY - height * 0.5f;

        roundedRect(shapeRenderer, x + 3f, y - 3f, width, height, 17f,
                0.16f, 0.05f, 0.03f, alpha * 0.38f);
        roundedRect(shapeRenderer, x, y, width, height, 17f,
                0.38f, 0.115f, 0.055f, alpha * 0.96f);
        roundedRect(shapeRenderer, x + 4f, y + 4f, width - 8f, height - 8f, 13f,
                0.97f, 0.86f, 0.66f, alpha * 0.98f);

        float selectedX = leftButton ? x + 6f : centerX + 2f;
        roundedRect(shapeRenderer, selectedX, y + 31f, 17f, 17f, 5f,
                0.98f, 0.68f, 0.14f, alpha * 0.96f);
        shapeRenderer.setColor(0.37f, 0.11f, 0.055f, alpha * 0.78f);
        shapeRenderer.rect(centerX - 1f, y + 29f, 2f, 19f);
        roundedRect(shapeRenderer, centerX - 3f, y + 19f, 6f, 11f, 3f,
                0.37f, 0.11f, 0.055f, alpha * 0.82f);
    }

    private void drawTitleRibbon(ShapeRenderer shapeRenderer, float panelY, float alpha) {
        float centerX = Constants.WORLD_WIDTH * 0.5f;
        float ribbonX = centerX - RIBBON_WIDTH * 0.5f;
        float ribbonY = panelY + PANEL_HEIGHT - 16f;

        shapeRenderer.setColor(0.17f, 0.05f, 0.03f, alpha * 0.42f);
        roundedRect(shapeRenderer, ribbonX + 3f, ribbonY - 3f, RIBBON_WIDTH, RIBBON_HEIGHT, 8f,
                0.17f, 0.05f, 0.03f, alpha * 0.42f);

        roundedRect(shapeRenderer, ribbonX, ribbonY, RIBBON_WIDTH, RIBBON_HEIGHT, 8f,
                0.38f, 0.115f, 0.055f, alpha * 0.98f);
        roundedRect(shapeRenderer, ribbonX + 5f, ribbonY + 5f, RIBBON_WIDTH - 10f, RIBBON_HEIGHT - 10f, 5f,
                0.98f, 0.73f, 0.22f, alpha * 0.96f);
    }

    private void drawText(SpriteBatch batch, OrthographicCamera camera, float panelY, float alpha) {
        float yDelta = panelY - PANEL_Y;
        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        batch.setColor(1f, 1f, 1f, alpha);

        float titleY = panelY + PANEL_HEIGHT + 2f;
        TextureDraw.centeredWithin(batch, titleText, Constants.WORLD_WIDTH * 0.5f, titleY, 0.45f,
                RIBBON_WIDTH - 22f);

        drawKeyText(batch, keyTexts[0], controlX(0) - 26f, ICON_CENTER_Y + yDelta, 34f);
        drawKeyText(batch, keyTexts[1], controlX(0) + 26f, ICON_CENTER_Y + yDelta, 34f);
        drawKeyText(batch, keyTexts[2], controlX(1), ICON_CENTER_Y + yDelta, 98f);
        drawKeyText(batch, keyTexts[3], controlX(2), ICON_CENTER_Y + yDelta, 88f);

        for (int i = 0; i < actionTexts.length; i++) {
            float actionY = ACTION_CENTER_Y + yDelta + (i >= 3 ? 4f : 0f);
            TextureDraw.centeredWithin(batch, actionTexts[i], controlX(i), actionY, 0.35f, 138f);
        }
        TextureDraw.centeredWithin(batch, holdText, controlX(3), ACTION_CENTER_Y - 8f + yDelta, 0.22f, 100f);
        TextureDraw.centeredWithin(batch, clickText, controlX(4), ACTION_CENTER_Y - 8f + yDelta, 0.22f, 100f);

        batch.setColor(Color.WHITE);
        batch.end();
    }

    private void drawKeyText(SpriteBatch batch, Texture texture, float centerX, float centerY, float maxWidth) {
        TextureDraw.centeredWithin(batch, texture, centerX, centerY, 0.34f, maxWidth);
    }

    private float controlX(int index) {
        return FIRST_CONTROL_X + index * CONTROL_GAP;
    }

    private float alpha() {
        if (displayTimer >= DISPLAY_DURATION) {
            return 0f;
        }
        float fadeIn = MathUtils.clamp(displayTimer / FADE_IN_DURATION, 0f, 1f);
        float fadeOut = displayTimer <= FADE_OUT_START
                ? 1f
                : 1f - MathUtils.clamp((displayTimer - FADE_OUT_START) / FADE_OUT_DURATION, 0f, 1f);
        return smoothStep(fadeIn) * smoothStep(fadeOut);
    }

    private float smoothStep(float value) {
        return value * value * (3f - 2f * value);
    }

    private void roundedRect(ShapeRenderer shapeRenderer, float x, float y, float width, float height, float radius,
                             float red, float green, float blue, float alpha) {
        float safeRadius = Math.min(radius, Math.min(width, height) * 0.5f);
        shapeRenderer.setColor(red, green, blue, alpha);
        shapeRenderer.rect(x + safeRadius, y, width - safeRadius * 2f, height);
        shapeRenderer.rect(x, y + safeRadius, width, height - safeRadius * 2f);
        shapeRenderer.circle(x + safeRadius, y + safeRadius, safeRadius);
        shapeRenderer.circle(x + width - safeRadius, y + safeRadius, safeRadius);
        shapeRenderer.circle(x + safeRadius, y + height - safeRadius, safeRadius);
        shapeRenderer.circle(x + width - safeRadius, y + height - safeRadius, safeRadius);
    }
}
