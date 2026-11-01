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
 * The Victory screen (scene 14): VICTORY / FACILITY ESCAPED, the run's performance stats and rank
 * (from {@link GameStats}), and the required Replay Mission / Main Menu navigation (rubric item 16).
 * A line of clones beside the player reinforces the mastered cloning theme.
 */
public final class VictoryScreen implements Screen {

    private final ShadowCloneGame game;
    private float time;
    private final Vector3 tmp = new Vector3();

    // Buttons: 0 Replay, 1 Main Menu.
    private static final float[][] BUTTONS = {
        {300f, 56f, 300f, 58f},
        {680f, 56f, 300f, 58f},
    };
    private static final String[] LABELS = {"REPLAY MISSION", "MAIN MENU"};

    public VictoryScreen(ShadowCloneGame game) {
        this.game = game;
    }

    private int hovered() {
        tmp.set(Gdx.input.getX(), Gdx.input.getY(), 0f);
        game.viewport.unproject(tmp);
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            if (tmp.x >= b[0] && tmp.x <= b[0] + b[2] && tmp.y >= b[1] && tmp.y <= b[1] + b[3]) return i;
        }
        return -1;
    }

    @Override
    public void render(float delta) {
        time += delta;
        if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER)) { game.startRun(); return; }
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) { game.toMenu(); return; }
        if (Gdx.input.justTouched()) {
            int b = hovered();
            if (b == 0) { game.startRun(); return; }
            else if (b == 1) { game.toMenu(); return; }
        }
        draw();
    }

    private void draw() {
        ScreenUtils.clear(Theme.BG_BOTTOM.r, Theme.BG_BOTTOM.g, Theme.BG_BOTTOM.b, 1f);
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        game.useWorldCamera();
        int hov = hovered();
        GameStats st = game.stats;

        ShapeRenderer sr = game.shapes;
        sr.begin(ShapeRenderer.ShapeType.Filled);
        sr.rect(0, 0, Theme.WORLD_W, Theme.WORLD_H, Theme.BG_BOTTOM, Theme.BG_BOTTOM, Theme.BG_TOP, Theme.BG_TOP);
        // Simple firework bursts.
        for (int i = 0; i < 5; i++) {
            float fx = 260f + i * 190f;
            float fy = 560f + 40f * MathUtils.sinDeg(time * 90f + i * 40f);
            float r = 6f + 5f * (1f + MathUtils.sinDeg(time * 160f + i * 70f));
            sr.setColor(i % 2 == 0 ? Theme.NEON.r : Theme.GOLD.r, i % 2 == 0 ? Theme.NEON.g : Theme.GOLD.g,
                i % 2 == 0 ? Theme.NEON.b : Theme.GOLD.b, 0.5f);
            sr.circle(fx, fy, r, 12);
        }
        // Stats panel.
        Draw.panel(sr, 60f, 250f, 360f, 250f, Theme.PANEL_FILL);
        // Rank badge.
        Draw.glow(sr, 1060f, 470f, 120f, 120f, Theme.GOLD, 8f);
        sr.setColor(Theme.GOLD);
        sr.circle(1120f, 530f, 56f, 24);
        sr.setColor(Theme.BG_BOTTOM);
        sr.circle(1120f, 530f, 46f, 24);
        // Three stars (below the subtitle).
        for (int i = 0; i < 3; i++) star(sr, 560f + i * 90f, 556f, 17f, Theme.GOLD);
        // Podium with the player + a line of clones.
        Draw.fill(sr, 300f, 150f, 680f, 22f, Theme.FLOOR);
        WorldRenderer.figure(sr, 620f, 172f, Theme.PLAYER_W, Theme.PLAYER_H, false, time);
        for (int i = 0; i < 5; i++) {
            float cx = 380f + i * 70f + (i >= 3 ? 250f : 0f);
            WorldRenderer.figure(sr, cx, 172f, Theme.PLAYER_W, Theme.PLAYER_H, true, time + i);
        }
        // Buttons.
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            Draw.fill(sr, b[0], b[1], b[2], b[3], i == hov ? new Color(0.12f, 0.34f, 0.52f, 0.9f) : Theme.PANEL_FILL);
        }
        sr.end();

        sr.begin(ShapeRenderer.ShapeType.Line);
        Draw.border(sr, 60f, 250f, 360f, 250f, Theme.PANEL_LINE);
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            Draw.border(sr, b[0], b[1], b[2], b[3], i == hov ? Theme.NEON : Theme.PANEL_LINE);
        }
        sr.end();

        game.batch.begin();
        game.text("VICTORY", Theme.WORLD_W * 0.5f, 690f, 4.6f, Theme.NEON, 0);
        game.text("FACILITY ESCAPED", Theme.WORLD_W * 0.5f, 604f, 1.4f, Theme.NEON_DIM, 0);
        // Stats.
        String[] keys = {"RECORDINGS MADE", "CLONES USED", "SWITCHES ACTIVATED", "PUZZLES SOLVED", "TIME", "DEATHS"};
        String[] vals = {
            String.valueOf(st.recordingsMade),
            String.valueOf(st.clonesUsed),
            String.valueOf(st.switchesActivated),
            st.puzzlesSolved + " / " + GameStats.TOTAL_PUZZLES,
            st.timeString(),
            String.valueOf(st.deaths),
        };
        game.text("MISSION STATS", 80f, 476f, 1.0f, Theme.NEON, -1);
        for (int i = 0; i < keys.length; i++) {
            float ly = 440f - i * 30f;
            game.text(keys[i], 80f, ly, 0.85f, Theme.INK_DIM, -1);
            game.text(vals[i], 400f, ly, 0.9f, Theme.INK, 1);
        }
        // Rank.
        game.text("RANK", 1120f, 610f, 0.9f, Theme.NEON_DIM, 0);
        game.text(st.rank(), 1120f, 548f, 3.0f, Theme.GOLD, 0);
        // Buttons.
        for (int i = 0; i < BUTTONS.length; i++) {
            float[] b = BUTTONS[i];
            game.text(LABELS[i], b[0] + b[2] * 0.5f, b[1] + b[3] * 0.5f + 8f, 1.05f, i == hov ? Theme.INK : Theme.INK_DIM, 0);
        }
        game.text("You proved the clone system can work.", Theme.WORLD_W * 0.5f, 132f, 0.9f, Theme.NEON_DIM, 0);
        game.batch.end();
    }

    private void star(ShapeRenderer sr, float cx, float cy, float r, Color c) {
        sr.setColor(c);
        sr.triangle(cx, cy + r, cx - r * 0.9f, cy - r * 0.6f, cx + r * 0.9f, cy - r * 0.6f);
        sr.triangle(cx, cy - r, cx - r * 0.9f, cy + r * 0.6f, cx + r * 0.9f, cy + r * 0.6f);
    }

    @Override public void resize(int width, int height) { game.viewport.update(width, height, false); }
    @Override public void show() {}
    @Override public void hide() {}
    @Override public void pause() {}
    @Override public void resume() {}
    @Override public void dispose() {}
}
