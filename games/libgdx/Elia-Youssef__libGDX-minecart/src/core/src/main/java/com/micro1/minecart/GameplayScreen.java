package com.micro1.minecart;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * Gameplay screen: a thin render/input shell over {@link MineCartWorld}. Feeds route keys and
 * the restart click into the world, then draws the HUD, tracks, junction, caves, carts, and the
 * win/lose overlay. All simulation rules live in the world; this class owns no game state beyond
 * the click hit-rectangle.
 */
public class GameplayScreen extends ScreenAdapter {

    private static final float RAIL_THICKNESS = 4f;
    private static final float RAIL_HALF_SPACING = 10f; // rails 20px apart
    private static final float JUNCTION_SIZE = 40f;
    private static final float CAVE_W = 120f;
    private static final float CAVE_H = 60f;
    private static final float INDICATOR_SIZE = 16f;

    private static final Color HUD_GREY = new Color(0.13f, 0.13f, 0.15f, 1f);
    private static final Color PLAYFIELD_GREEN = new Color(0.05f, 0.16f, 0.07f, 1f);
    private static final Color RAIL_GREY = new Color(0.75f, 0.75f, 0.78f, 1f);
    private static final Color ROUTE_YELLOW = new Color(1f, 0.85f, 0.10f, 1f);
    private static final Color CART_BLUE = new Color(0.10f, 0.22f, 0.86f, 1f);
    private static final Color IND_RED = new Color(0.90f, 0.15f, 0.15f, 1f);
    private static final Color IND_GREEN = new Color(0.15f, 0.80f, 0.20f, 1f);
    private static final Color IND_MAGENTA = new Color(0.85f, 0.10f, 0.85f, 1f);
    private static final Color CAVE_CYAN = new Color(0.10f, 0.85f, 0.92f, 1f);
    private static final Color OVERLAY_DIM = new Color(0f, 0f, 0f, 0.62f);

    private final MineCartGame game;
    private final MineCartWorld world = new MineCartWorld();
    private final Rectangle restartButton = new Rectangle();
    private final Vector3 touch = new Vector3();

    public GameplayScreen(MineCartGame game) {
        this.game = game;
    }

    @Override
    public void render(float delta) {
        handleInput();
        world.update(delta);
        draw();
    }

    private void handleInput() {
        if (world.getState() == MineCartWorld.State.PLAYING) {
            if (Gdx.input.isKeyJustPressed(Input.Keys.UP) || Gdx.input.isKeyJustPressed(Input.Keys.W)) {
                world.setRoute(MineCartWorld.UPPER);
            }
            if (Gdx.input.isKeyJustPressed(Input.Keys.DOWN) || Gdx.input.isKeyJustPressed(Input.Keys.S)) {
                world.setRoute(MineCartWorld.LOWER);
            }
            if (Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
                world.setRoute(MineCartWorld.MIDDLE);
            }
        } else {
            // End state: only the restart button responds.
            game.centeredBounds(restartLabel(), 24f, 640f, 430f, 34f, 18f, restartButton);
            if (Gdx.input.justTouched()) {
                game.camera.unproject(touch.set(Gdx.input.getX(), Gdx.input.getY(), 0f));
                if (restartButton.contains(touch.x, touch.y)) {
                    world.reset();
                }
            }
        }
    }

    private String restartLabel() {
        return world.getState() == MineCartWorld.State.WON ? "PLAY AGAIN" : "RETRY";
    }

    private void draw() {
        ScreenUtils.clear(0f, 0f, 0f, 1f);
        ShapeRenderer s = game.shapes;
        s.setProjectionMatrix(game.camera.combined);

        s.begin(ShapeRenderer.ShapeType.Filled);
        s.setColor(PLAYFIELD_GREEN);
        s.rect(0f, 40f, MineCartWorld.WIDTH, MineCartWorld.HEIGHT - 40f);
        s.setColor(HUD_GREY);
        s.rect(0f, 0f, MineCartWorld.WIDTH, 40f);

        drawTracks(s);

        s.setColor(ROUTE_YELLOW);
        s.rect(MineCartWorld.JUNCTION_X - JUNCTION_SIZE / 2f, MineCartWorld.TRACK_Y[MineCartWorld.MIDDLE] - JUNCTION_SIZE / 2f,
            JUNCTION_SIZE, JUNCTION_SIZE);

        s.setColor(CAVE_CYAN);
        for (int t = 0; t < 3; t++) {
            s.rect(MineCartWorld.CAVE_X, MineCartWorld.TRACK_Y[t] - CAVE_H / 2f, CAVE_W, CAVE_H);
        }

        drawCarts(s);
        s.end();

        if (world.getState() != MineCartWorld.State.PLAYING) {
            Gdx.gl.glEnable(GL20.GL_BLEND);
            s.begin(ShapeRenderer.ShapeType.Filled);
            s.setColor(OVERLAY_DIM);
            s.rect(0f, 0f, MineCartWorld.WIDTH, MineCartWorld.HEIGHT);
            s.end();
        }

        game.batch.setProjectionMatrix(game.camera.combined);
        game.batch.begin();
        game.drawLeft("TIME: " + world.getSurvivalSeconds(), 20f, 14f, 20f, Color.WHITE);
        game.drawRight("GOLDS: " + world.getGold(), 20f, MineCartWorld.WIDTH - 14f, 20f, Color.WHITE);
        drawOverlayText();
        game.batch.end();
    }

    private void drawTracks(ShapeRenderer s) {
        s.setColor(RAIL_GREY);
        drawHorizontalRails(s, 0f, MineCartWorld.CAVE_X, MineCartWorld.TRACK_Y[MineCartWorld.MIDDLE]);
        drawHorizontalRails(s, MineCartWorld.JUNCTION_X, MineCartWorld.CAVE_X, MineCartWorld.TRACK_Y[MineCartWorld.UPPER]);
        drawHorizontalRails(s, MineCartWorld.JUNCTION_X, MineCartWorld.CAVE_X, MineCartWorld.TRACK_Y[MineCartWorld.LOWER]);
        drawVerticalRails(s, MineCartWorld.JUNCTION_X, MineCartWorld.TRACK_Y[MineCartWorld.UPPER], MineCartWorld.TRACK_Y[MineCartWorld.LOWER]);

        // Highlight the selected outgoing route in bright yellow.
        int r = world.getSelectedRoute();
        s.setColor(ROUTE_YELLOW);
        drawHorizontalRails(s, MineCartWorld.JUNCTION_X, MineCartWorld.CAVE_X, MineCartWorld.TRACK_Y[r]);
        if (r != MineCartWorld.MIDDLE) {
            float y0 = Math.min(MineCartWorld.TRACK_Y[MineCartWorld.MIDDLE], MineCartWorld.TRACK_Y[r]);
            float y1 = Math.max(MineCartWorld.TRACK_Y[MineCartWorld.MIDDLE], MineCartWorld.TRACK_Y[r]);
            drawVerticalRails(s, MineCartWorld.JUNCTION_X, y0, y1);
        }
    }

    private void drawHorizontalRails(ShapeRenderer s, float x0, float x1, float centerY) {
        float len = x1 - x0;
        s.rect(x0, centerY - RAIL_HALF_SPACING - RAIL_THICKNESS / 2f, len, RAIL_THICKNESS);
        s.rect(x0, centerY + RAIL_HALF_SPACING - RAIL_THICKNESS / 2f, len, RAIL_THICKNESS);
    }

    private void drawVerticalRails(ShapeRenderer s, float centerX, float y0, float y1) {
        float len = y1 - y0;
        s.rect(centerX - RAIL_HALF_SPACING - RAIL_THICKNESS / 2f, y0, RAIL_THICKNESS, len);
        s.rect(centerX + RAIL_HALF_SPACING - RAIL_THICKNESS / 2f, y0, RAIL_THICKNESS, len);
    }

    private void drawCarts(ShapeRenderer s) {
        Array<Cart> carts = world.getCarts();
        for (int i = 0; i < carts.size; i++) {
            Cart c = carts.get(i);
            s.setColor(CART_BLUE);
            s.rect(c.x, c.y, MineCartWorld.CART_W, MineCartWorld.CART_H);
            s.setColor(indicatorColor(c.destination));
            s.rect(c.x + MineCartWorld.CART_W - INDICATOR_SIZE - 6f,
                c.y + (MineCartWorld.CART_H - INDICATOR_SIZE) / 2f, INDICATOR_SIZE, INDICATOR_SIZE);
        }
    }

    private Color indicatorColor(int destination) {
        if (destination == MineCartWorld.UPPER) {
            return IND_RED;
        }
        if (destination == MineCartWorld.MIDDLE) {
            return IND_GREEN;
        }
        return IND_MAGENTA;
    }

    private void drawOverlayText() {
        MineCartWorld.State state = world.getState();
        if (state == MineCartWorld.State.PLAYING) {
            return;
        }
        String title = state == MineCartWorld.State.WON ? "YOU WIN" : "DISASTER";
        game.drawCentered(title, 48f, 640f, 300f, Color.WHITE);
        game.drawCentered("FINAL GOLDS: " + world.getGold(), 30f, 640f, 370f, Color.WHITE);
        game.drawCentered(restartLabel(), 24f, 640f, 430f, Color.WHITE);
    }
}
