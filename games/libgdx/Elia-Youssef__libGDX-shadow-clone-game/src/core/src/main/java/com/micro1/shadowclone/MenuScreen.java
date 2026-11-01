package com.micro1.shadowclone;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * The Main Menu (scene 1, rubric item 21): the title SHADOW CLONE, Start Game / Controls / Exit, a
 * looping demo of the dark player with a cyan clone trailing it, and a holographic cloning pod - the
 * clean sci-fi facility look. Start begins the run at the Clone Tutorial Room (item 22); Exit closes
 * the application (item 23).
 */
public final class MenuScreen implements Screen {

    private final ShadowCloneGame game;
    private float time;
    private final Vector3 tmp = new Vector3();
    private boolean showControls;

    // Buttons: {x, y, w, h}. 0 Start, 1 Controls, 2 Exit.
    private static final float[][] BUTTONS = {
        {80f, 356f, 400f, 58f},
        {80f, 286f, 400f, 58f},
        {80f, 216f, 400f, 58f},
    };
    private static final String[] LABELS = {"START GAME", "CONTROLS", "EXIT"};

    public MenuScreen(ShadowCloneGame game) {
        this.game = game;
    }

    private int buttonAt(float wx, float wy) {
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            if (wx >= b[0] && wx <= b[0] + b[2] && wy >= b[1] && wy <= b[1] + b[3]) return i;
        }
        return -1;
    }

    private int hovered() {
        tmp.set(Gdx.input.getX(), Gdx.input.getY(), 0f);
        game.viewport.unproject(tmp);
        return buttonAt(tmp.x, tmp.y);
    }

    @Override
    public void render(float delta) {
        time += delta;
        if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER) || Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
            game.startRun();
            return;
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.C)) showControls = !showControls;
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            if (showControls) showControls = false; else Gdx.app.exit();
        }
        if (Gdx.input.justTouched()) {
            int b = hovered();
            if (b == 0) { game.startRun(); return; }
            else if (b == 1) showControls = !showControls;
            else if (b == 2) Gdx.app.exit();
        }
        draw();
    }

    private void draw() {
        ScreenUtils.clear(Theme.BG_BOTTOM.r, Theme.BG_BOTTOM.g, Theme.BG_BOTTOM.b, 1f);
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        game.useWorldCamera();
        int hov = hovered();

        ShapeRenderer sr = game.shapes;
        sr.begin(ShapeRenderer.ShapeType.Filled);
        // Backdrop.
        sr.rect(0, 0, Theme.WORLD_W, Theme.WORLD_H, Theme.BG_BOTTOM, Theme.BG_BOTTOM, Theme.BG_TOP, Theme.BG_TOP);
        sr.setColor(Theme.WALL_LINE.r, Theme.WALL_LINE.g, Theme.WALL_LINE.b, 0.4f);
        for (float x = 0; x <= Theme.WORLD_W; x += 150f) sr.rect(x, 0, 2f, Theme.WORLD_H);
        // Demo stage on the right: platform, player, trailing clone, cloning pod.
        float stageY = 250f;
        Draw.fill(sr, 560f, stageY - 30f, 700f, 30f, Theme.FLOOR);
        Draw.fill(sr, 560f, stageY - 6f, 700f, 6f, Theme.FLOOR_TOP);
        float px = 820f + 150f * MathUtils.sin(time * 0.8f);
        float cxp = 820f + 150f * MathUtils.sin(time * 0.8f - 0.7f);
        WorldRenderer.figure(sr, cxp, stageY, Theme.PLAYER_W, Theme.PLAYER_H, true, time);
        WorldRenderer.figure(sr, px, stageY, Theme.PLAYER_W, Theme.PLAYER_H, false, time);
        cloningPod(sr, 1150f, stageY + 20f, time);
        // Buttons.
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            boolean hot = i == hov;
            Color fill = hot ? new Color(0.12f, 0.34f, 0.52f, 0.9f) : Theme.PANEL_FILL;
            Draw.fill(sr, b[0], b[1], b[2], b[3], fill);
            Draw.fill(sr, b[0], b[1], 6f, b[3], hot ? Theme.NEON : Theme.NEON_DIM);
        }
        sr.end();

        sr.begin(ShapeRenderer.ShapeType.Line);
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            Draw.border(sr, b[0], b[1], b[2], b[3], i == hov ? Theme.NEON : Theme.PANEL_LINE);
        }
        if (showControls) Draw.border(sr, 300f, 90f, 680f, 120f, Theme.NEON);
        sr.end();

        game.batch.begin();
        // Title.
        game.text("SHADOW", 80f, 660f, 5.6f, Theme.NEON, -1);
        game.text("CLONE", 80f, 560f, 5.6f, Theme.NEON, -1);
        game.text("BECOME YOUR OWN TEAM", 86f, 470f, 1.25f, Theme.NEON_DIM, -1);
        // Buttons.
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            game.text(LABELS[i], b[0] + 28f, b[1] + b[3] * 0.5f + 8f, 1.35f, i == hov ? Theme.INK : Theme.INK_DIM, -1);
        }
        // Demo caption (above the demo stage so it clears the figures).
        game.text("Every 5 seconds your actions are replayed by a clone.", 560f, 360f, 0.85f, Theme.INK_DIM, -1);
        game.text("Use your past selves to solve the facility.", 560f, 336f, 0.85f, Theme.INK_DIM, -1);
        game.text("v1.0  -  libGDX", 80f, 150f, 0.75f, Theme.NEON_FAINT, -1);
        if (showControls) {
            game.text("CONTROLS", 640f, 190f, 1.1f, Theme.NEON, 0);
            game.text("MOVE  Left / Right (or A / D)      JUMP  Space (or W / Up)", 640f, 158f, 0.85f, Theme.INK, 0);
            game.text("USE  E      RESET RECORDING  R      RESTART LEVEL  Backspace", 640f, 130f, 0.85f, Theme.INK, 0);
            game.text("A clone deploys every 5 seconds and repeats what you did.", 640f, 106f, 0.8f, Theme.NEON_DIM, 0);
        } else {
            game.text("click START GAME  (or press Enter)", 86f, 180f, 0.85f, Theme.INK_DIM, -1);
        }
        game.batch.end();
    }

    private void cloningPod(ShapeRenderer sr, float x, float y, float time) {
        float pulse = 0.4f + 0.2f * MathUtils.sinDeg(time * 120f);
        Draw.fill(sr, x, y, 52f, 150f, Theme.WALL);
        Draw.fill(sr, x + 8f, y + 10f, 36f, 130f, new Color(0.10f, 0.30f, 0.45f, 0.6f));
        sr.setColor(Theme.NEON.r, Theme.NEON.g, Theme.NEON.b, pulse);
        sr.rect(x + 19f, y + 20f, 14f, 110f);
    }

    @Override public void resize(int width, int height) { game.viewport.update(width, height, false); }
    @Override public void show() {}
    @Override public void hide() {}
    @Override public void pause() {}
    @Override public void resume() {}
    @Override public void dispose() {}
}
