package com.micro1.territory;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

/**
 * Renders the Territory Challenge and routes input into {@link GameLogic}.
 * Fixed 1100x900 world.
 * The partitioned rectangle is drawn from the round's shape PNG at a fixed
 * on-screen rect; the
 * hit-detection polygons are mapped proportionally onto that same rect, so
 * clicks map to the
 * correct territory (convex and concave).
 */
public class GameScreen implements Screen {

    private static final float WORLD_W = 1100f;
    private static final float WORLD_H = 900f;

    // Central play rectangle (bottom-left origin, y-up). Each round derives its
    // height from the
    // active PNG, because the four supplied assets differ by a few pixels in their
    // dimensions.
    private static final float RECT_X = 45f;
    private static final float RECT_Y = 250f;
    private static final float RECT_W = 740f;
    private static final float BASE_RECT_H = RECT_W * 465f / 721f;
    private static final float TIMER_X = WORLD_W / 2f;

    // Leaderboard panel (right side).
    private static final float LB_X = 812f;
    private static final float LB_W = 250f;
    private static final float LB_BOT = RECT_Y;

    private static final Color BG = new Color(0.06f, 0.07f, 0.11f, 1f);
    private static final Color PANEL = new Color(0.13f, 0.15f, 0.21f, 1f);
    private static final Color HIDDEN = new Color(0.15f, 0.17f, 0.23f, 1f);
    private static final Color WHITE = Color.WHITE;
    private static final Color MUTED = new Color(0.75f, 0.78f, 0.85f, 1f);
    private static final Color TIMER_GREEN = new Color(0.45f, 0.9f, 0.5f, 1f);
    private static final Color GOLD = new Color(0.98f, 0.82f, 0.32f, 1f);
    private static final Color WIN = new Color(0.45f, 0.9f, 0.5f, 1f);
    private static final Color LOSE = new Color(0.95f, 0.42f, 0.42f, 1f);

    private final GameLogic logic = new GameLogic(new Random());

    private final OrthographicCamera camera = new OrthographicCamera();
    private final Viewport viewport = new FitViewport(WORLD_W, WORLD_H, camera);
    private SpriteBatch batch;
    private ShapeRenderer shapes;
    private BitmapFont font;
    private final GlyphLayout layout = new GlyphLayout();
    private final Map<String, Texture> shapeTextures = new HashMap<String, Texture>();

    // Offscreen QA capture (-Dcapture=DIR): render each screen to a PNG then exit.
    // private final String captureDir = System.getProperty("capture");
    // private int capStep = 0;
    // private boolean capSceneRendered = false;

    // private static final class Scene {
    // final String label; final GamePhase phase; final int round;
    // final int[] sel, rs, tot;
    // Scene(String l, GamePhase p, int r, int[] s, int[] a, int[] t) {
    // label = l; phase = p; round = r; sel = s; rs = a; tot = t;
    // }
    // }
    // private final Scene[] scenes = {
    // new Scene("01_start", GamePhase.START, 0, z(-1), z(0), z(0)),
    // new Scene("02_countdown", GamePhase.COUNTDOWN, 0, z(-1), z(0), z(0)),
    // new Scene("03_select_r1", GamePhase.SELECT, 0, new int[]{3, 1, 3, 0}, z(0),
    // z(0)),
    // new Scene("04_result_r1", GamePhase.RESULT, 0, new int[]{3, 1, 3, 0}, new
    // int[]{1, 0, 1, 0}, new int[]{1, 0, 1, 0}),
    // new Scene("05_select_r3", GamePhase.SELECT, 2, new int[]{1, 2, 3, 0}, z(0),
    // new int[]{1, 0, 1, 0}),
    // new Scene("06_result_r4", GamePhase.RESULT, 3, new int[]{1, 2, 1, 0}, new
    // int[]{1, 0, 1, 0}, new int[]{3, 1, 3, 1}),
    // new Scene("07_final", GamePhase.FINAL, 3, new int[]{1, 2, 1, 0}, new int[]{1,
    // 0, 1, 0}, new int[]{3, 1, 3, 1}),
    // };
    // private static int[] z(int v) {
    // return new int[] { v, v, v, v };
    // }

    @Override
    public void show() {
        batch = new SpriteBatch();
        shapes = new ShapeRenderer();
        font = new BitmapFont();
        font.getRegion().getTexture().setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
        font.setUseIntegerPositions(false);

        for (String name : new String[] { "shape1.png", "shape2.png", "shape3.png", "shape4.png" }) {
            Texture tex = new Texture(Gdx.files.internal(name));
            tex.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
            shapeTextures.put(name, tex);
        }
        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override
            public boolean keyDown(int keycode) {
                if (keycode == Input.Keys.S) {
                    logic.pressStart();
                    return true;
                }
                if (keycode == Input.Keys.N) {
                    logic.pressNext();
                    return true;
                }
                return false;
            }

            @Override
            public boolean touchDown(int screenX, int screenY, int pointer, int button) {
                if (button != Input.Buttons.LEFT) {
                    return false;
                }
                Vector3 w = viewport.unproject(new Vector3(screenX, screenY, 0f));
                float rectH = rectH();
                float cx = (w.x - RECT_X) / RECT_W * 100f;
                float cy = (RECT_Y + rectH - w.y) / rectH * 60f; // world y-up -> coord y-down
                logic.clickCoord(cx, cy);
                return true;
            }
        });
    }

    // --- coordinate mapping (100x60 territory space -> screen) ---
    private float sx(float cx) {
        return RECT_X + cx / 100f * RECT_W;
    }

    private float sy(float cy) {
        float rectH = rectH();
        return RECT_Y + rectH - cy / 60f * rectH;
    }

    @Override
    public void render(float delta) {
        // if (captureDir != null) {
        // if (capStep >= scenes.length) {
        // Gdx.app.exit();
        // return;
        // }
        // Scene s = scenes[capStep];
        // logic.debugConfigure(s.phase, s.round, s.sel, s.rs, s.tot);
        // } else {
        logic.update(delta);
        // }
        ScreenUtils.clear(BG);
        viewport.apply();
        camera.update();
        shapes.setProjectionMatrix(camera.combined);
        batch.setProjectionMatrix(camera.combined);
        Gdx.gl.glEnable(GL20.GL_BLEND);

        GamePhase phase = logic.phase();

        // PASS 1: filled backgrounds
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        drawFilled(phase);
        shapes.end();

        // PASS 2: textures (the partitioned rectangle image)
        batch.begin();
        if (phase == GamePhase.SELECT || phase == GamePhase.RESULT) {
            Texture tex = shapeTextures.get(logic.currentRound().assetName);
            batch.draw(tex, RECT_X, RECT_Y, RECT_W, rectH());
        }
        batch.end();

        // PASS 2.4: largest-territory highlight, drawn UNDER the reveal box
        if (phase == GamePhase.RESULT) {
            shapes.begin(ShapeRenderer.ShapeType.Line);
            drawHighlight();
            shapes.end();
        }

        // PASS 2.5: result center-overlay box, drawn OVER the highlight + rectangle
        // image
        if (phase == GamePhase.RESULT) {
            shapes.begin(ShapeRenderer.ShapeType.Filled);
            shapes.setColor(0.07f, 0.09f, 0.13f, 0.96f);
            shapes.rect(RECT_X + RECT_W / 2f - 215f, rectMidY() - 52f, 430f, 104f);
            shapes.end();
        }

        // PASS 3: line shapes (borders, highlight, marks)
        shapes.begin(ShapeRenderer.ShapeType.Line);
        drawLines(phase);
        shapes.end();

        // PASS 4: text
        batch.begin();
        drawText(phase);
        batch.end();

        // if (captureDir != null) {
        // // Keep each synthetic scene on screen for one complete frame before reading
        // the
        // // backbuffer. This avoids partially updated captures on double-buffered
        // drivers.
        // if (!capSceneRendered) {
        // capSceneRendered = true;
        // return;
        // }
        // Gdx.gl.glFinish();
        // Pixmap pm = Pixmap.createFromFrameBuffer(0, 0,
        // Gdx.graphics.getBackBufferWidth(), Gdx.graphics.getBackBufferHeight());
        // FileHandle output = Gdx.files.absolute(captureDir + "/" +
        // scenes[capStep].label + ".png");
        // output.parent().mkdirs();
        // PixmapIO.PNG writer = new PixmapIO.PNG();
        // writer.setFlipY(true); // OpenGL framebuffer origin is bottom-left; PNG
        // origin is top-left.
        // try {
        // writer.write(output, pm);
        // } catch (java.io.IOException e) {
        // throw new RuntimeException("Could not write QA capture " + output.path(), e);
        // } finally {
        // writer.dispose();
        // pm.dispose();
        // }
        // capSceneRendered = false;
        // capStep++;
        // }
    }

    // ------------------------------------------------------------------ filled
    // pass
    private void drawFilled(GamePhase phase) {
        float rectH = rectH();
        // rectangle backdrop when hidden / empty
        if (phase == GamePhase.START || phase == GamePhase.COUNTDOWN) {
            shapes.setColor(phase == GamePhase.COUNTDOWN ? HIDDEN : BG);
            shapes.rect(rx(), RECT_Y, RECT_W, rectH);
        }
        // leaderboard panel (all phases except pure start/final title use it)
        if (phase == GamePhase.COUNTDOWN || phase == GamePhase.SELECT || phase == GamePhase.RESULT) {
            shapes.setColor(PANEL);
            shapes.rect(LB_X, LB_BOT, LB_W, lbTop() - LB_BOT);
        }
        // timer pill
        if (phase == GamePhase.COUNTDOWN || phase == GamePhase.SELECT) {
            shapes.setColor(0.10f, 0.12f, 0.16f, 1f);
            shapes.rect(TIMER_X - 75f, WORLD_H - 95f, 150f, 56f);
        }
        // Center transition overlay while the partition is hidden.
        if (phase == GamePhase.COUNTDOWN) {
            shapes.setColor(0.07f, 0.09f, 0.13f, 0.92f);
            shapes.rect(RECT_X + RECT_W / 2f - 180f, rectMidY() - 55f, 360f, 110f);
        }
        // competitor identity circles at the bottom
        if (phase != GamePhase.FINAL) {
            for (int i = 0; i < 4; i++) {
                Competitor c = logic.competitors()[i];
                shapes.setColor(c.color);
                shapes.circle(circleX(i), 150f, 30f, 40);
            }
        }
        // correct/incorrect badges by the circles (result)
        if (phase == GamePhase.RESULT) {
            int answer = logic.currentRound().largestIndex;
            for (int i = 0; i < 4; i++) {
                boolean correct = logic.competitors()[i].selection == answer;
                shapes.setColor(correct ? WIN : LOSE);
                shapes.circle(circleX(i) + 21f, 172f, 14f, 24);
            }
        }
        // final screen table backdrop
        if (phase == GamePhase.FINAL) {
            shapes.setColor(PANEL);
            shapes.rect(250f, 250f, 600f, 430f);
        }
    }

    // ------------------------------------------------------------------ line pass
    private void drawLines(GamePhase phase) {
        float rectH = rectH();
        // rectangle border (empty on start/countdown, around the image on
        // select/result; none on final)
        if (phase != GamePhase.FINAL) {
            shapes.setColor(phase == GamePhase.START ? MUTED : new Color(0.05f, 0.05f, 0.07f, 1f));
            shapes.rect(rx(), RECT_Y, RECT_W, rectH);
            if (phase == GamePhase.START) {
                // inner outline for the empty rectangle
                shapes.setColor(0.4f, 0.44f, 0.55f, 1f);
                shapes.rect(rx() + 6f, RECT_Y + 6f, RECT_W - 12f, rectH - 12f);
            }
        }
        if (phase == GamePhase.COUNTDOWN) {
            shapes.setColor(0.42f, 0.46f, 0.58f, 1f);
            shapes.rect(RECT_X + RECT_W / 2f - 180f, rectMidY() - 55f, 360f, 110f);
        }
        // Immediate visual confirmation of the player's polygon selection.
        if (phase == GamePhase.SELECT && logic.player().selection >= 0) {
            drawTerritoryOutline(logic.currentRound().territories[logic.player().selection], GOLD);
        }
        // (the largest-territory highlight is drawn earlier, before the reveal box, so
        // the box
        // cleanly covers the part of the outline behind it)
        // white check / cross on the result badges (thickened by overdrawing)
        if (phase == GamePhase.RESULT) {
            int answer = logic.currentRound().largestIndex;
            shapes.setColor(WHITE);
            for (int i = 0; i < 4; i++) {
                boolean correct = logic.competitors()[i].selection == answer;
                float bx = circleX(i) + 21f, by = 172f;
                for (int k = -1; k <= 1; k++) {
                    float o = k * 0.7f;
                    if (correct) {
                        shapes.line(bx - 6f + o, by, bx - 1f + o, by - 5f);
                        shapes.line(bx - 1f + o, by - 5f, bx + 7f + o, by + 6f);
                    } else {
                        shapes.line(bx - 6f + o, by + 6f, bx + 6f + o, by - 6f);
                        shapes.line(bx - 6f + o, by - 6f, bx + 6f + o, by + 6f);
                    }
                }
            }
            // result overlay box border
            shapes.setColor(0.42f, 0.46f, 0.58f, 1f);
            shapes.rect(RECT_X + RECT_W / 2f - 215f, rectMidY() - 52f, 430f, 104f);
        }
    }

    /**
     * Thick white outline around the largest territory (drawn in a Line pass, under
     * the box).
     */
    private void drawHighlight() {
        drawTerritoryOutline(logic.currentRound().largest(), WHITE);
    }

    /**
     * Thick outline around one territory. Must be called inside a ShapeRenderer
     * line pass.
     */
    private void drawTerritoryOutline(Territory territory, Color color) {
        float[] p = territory.polygon;
        float[][] offsets = { { 0f, 0f }, { -1f, 0f }, { 1f, 0f }, { 0f, -1f }, { 0f, 1f } };
        shapes.setColor(color);
        for (float[] offset : offsets) {
            for (int i = 0; i < p.length; i += 2) {
                int j = (i + 2) % p.length;
                shapes.line(sx(p[i]) + offset[0], sy(p[i + 1]) + offset[1],
                        sx(p[j]) + offset[0], sy(p[j + 1]) + offset[1]);
            }
        }
    }

    // ------------------------------------------------------------------ text pass
    private void drawText(GamePhase phase) {
        switch (phase) {
            case START:
                text("TERRITORY CHALLENGE", rx() + RECT_W / 2f, WORLD_H - 90f, 2.2f, WHITE, 0);
                text("Find the largest territory!", rx() + RECT_W / 2f, WORLD_H - 150f, 1.3f, MUTED, 0);
                text("Press S to Start", rx() + RECT_W / 2f, RECT_Y - 8f, 1.7f, GOLD, 0);
                break;

            case COUNTDOWN:
                drawTimer();
                drawLeaderboard(false);
                text("ROUND " + logic.roundNumber(), RECT_X + RECT_W / 2f,
                        rectMidY() + 24f, 2.0f, WHITE, 0);
                text("Get ready!", RECT_X + RECT_W / 2f,
                        rectMidY() - 18f, 1.25f, MUTED, 0);
                break;

            case SELECT:
                drawTimer();
                drawLeaderboard(false);
                text("Click on the territory you think is the largest!",
                        RECT_X + RECT_W / 2f, RECT_Y - 8f, 1.15f, MUTED, 0);
                break;

            case RESULT:
                drawLeaderboard(true);
                Round r = logic.currentRound();
                Territory best = r.largest();
                text("Largest Territory", RECT_X + RECT_W / 2f, rectMidY() + 34f, 1.3f, MUTED, 0);
                text(best.colorName + "  -  " + fmtPct(r.largestPct),
                        RECT_X + RECT_W / 2f, rectMidY() - 4f, 2.0f, best.color, 0);
                text("Press N for Next Round", RECT_X + RECT_W / 2f, RECT_Y - 8f, 1.4f, GOLD, 0);
                break;

            case FINAL:
                drawFinal();
                break;
            default:
                break;
        }
        // competitor labels under the circles
        if (phase != GamePhase.FINAL) {
            for (int i = 0; i < 4; i++) {
                text(logic.competitors()[i].name, circleX(i), 100f, 1.0f, MUTED, 0);
            }
        }
    }

    private void drawTimer() {
        int s = logic.timerSeconds();
        text("00:0" + s, TIMER_X, WORLD_H - 52f, 2.0f, TIMER_GREEN, 0);
    }

    private void drawLeaderboard(boolean result) {
        float top = lbTop();
        float cx = LB_X + LB_W / 2f;
        text("ROUND " + logic.roundNumber(), cx, top - 14f, 1.35f, WHITE, 0);
        text("Name", LB_X + 44f, top - 50f, 0.85f, MUTED, -1);
        text("Round", LB_X + LB_W - 78f, top - 50f, 0.85f, MUTED, 0);
        text("Total", LB_X + LB_W - 20f, top - 50f, 0.85f, MUTED, 1);
        Competitor[] rank = logic.ranking();
        float rowY = top - 88f;
        for (int i = 0; i < rank.length; i++) {
            Competitor c = rank[i];
            text((i + 1) + ".", LB_X + 14f, rowY, 1.0f, MUTED, -1);
            text(c.name, LB_X + 44f, rowY, 1.1f, WHITE, -1);
            text(result ? String.valueOf(c.roundScore) : "-", LB_X + LB_W - 78f, rowY,
                    1.0f, result && c.roundScore > 0 ? WIN : MUTED, 0);
            text("" + c.totalScore, LB_X + LB_W - 20f, rowY, 1.2f, GOLD, 1);
            rowY -= 46f;
        }
    }

    private void drawFinal() {
        text("GAME OVER", WORLD_W / 2f, 720f, 2.4f, WHITE, 0);
        text("FINAL RESULTS", WORLD_W / 2f, 668f, 1.4f, MUTED, 0);
        Competitor[] rank = logic.ranking();
        float rowY = 600f;

        text("Rank", 300f, rowY, 1.1f, MUTED, -1);
        text("Player", 430f, rowY, 1.1f, MUTED, -1);
        text("Total", 650f, rowY, 1.1f, MUTED, -1);
        text("Result", 760f, rowY, 1.1f, MUTED, -1);
        rowY -= 50f;
        for (int i = 0; i < rank.length; i++) {
            Competitor c = rank[i];
            boolean win = logic.isWinner(c);
            text((i + 1) + ".", 300f, rowY, 1.3f, win ? GOLD : MUTED, -1);
            text(c.name, 430f, rowY, 1.3f, WHITE, -1);
            text("" + c.totalScore, 665f, rowY, 1.3f, GOLD, 0);
            text(win ? "WINNER" : "LOSER", 790f, rowY, 1.3f, win ? WIN : LOSE, 0);
            rowY -= 52f;
        }
        text(winnerAnnouncement(), WORLD_W / 2f, 210f, 1.3f, WIN, 0);
    }

    private String winnerAnnouncement() {
        StringBuilder names = new StringBuilder();
        int count = 0;
        for (Competitor competitor : logic.ranking()) {
            if (logic.isWinner(competitor)) {
                if (count > 0) {
                    names.append(" & ");
                }
                names.append(competitor.name);
                count++;
            }
        }
        return (count == 1 ? "WINNER: " : "WINNERS: ") + names;
    }

    private String fmtPct(float pct) {
        return String.format(java.util.Locale.US, "%.2f%%", pct);
    }

    private float circleX(int i) {
        return rx() + 90f + i * 175f;
    }

    /**
     * Draw height that preserves the active supplied PNG's exact pixel aspect
     * ratio.
     */
    private float rectH() {
        if (logic.phase() != GamePhase.START) {
            Texture texture = shapeTextures.get(logic.currentRound().assetName);
            if (texture != null && texture.getWidth() > 0) {
                return RECT_W * texture.getHeight() / texture.getWidth();
            }
        }
        return BASE_RECT_H;
    }

    private float rectMidY() {
        return RECT_Y + rectH() / 2f;
    }

    private float lbTop() {
        return RECT_Y + rectH();
    }

    /**
     * Rectangle left edge: centered in the window on START (no leaderboard yet),
     * else left of the
     * leaderboard for play. Matches the reference (start = centered, play = left).
     */
    private float rx() {
        return logic.phase() == GamePhase.START ? (WORLD_W - RECT_W) / 2f : RECT_X;
    }

    /**
     * align: -1 left, 0 center, 1 right. (x,y) is the text anchor; y is the top of
     * the glyphs.
     */
    private void text(String s, float x, float y, float scale, Color color, int align) {
        font.getData().setScale(scale);
        font.setColor(color);
        layout.setText(font, s);
        float dx = align == 0 ? -layout.width / 2f : (align == 1 ? -layout.width : 0f);
        font.draw(batch, s, x + dx, y);
    }

    ///////// done
    ///
    ///
    ///
    ///
    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
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
        if (batch != null)
            batch.dispose();
        if (shapes != null)
            shapes.dispose();
        if (font != null)
            font.dispose();
        for (Texture t : shapeTextures.values()) {
            t.dispose();
        }
        shapeTextures.clear();
    }
}
