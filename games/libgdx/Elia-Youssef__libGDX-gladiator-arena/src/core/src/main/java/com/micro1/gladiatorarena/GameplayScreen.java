package com.micro1.gladiatorarena;

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
 * Gameplay screen: a thin render/input shell over {@link ArenaWorld}. Reads movement keys and the
 * shoot/restart clicks, feeds them to the world, then draws the arena, player, enemies,
 * projectiles, HUD, and the win/lose overlay. All simulation rules live in the world.
 */
public class GameplayScreen extends ScreenAdapter {

    private static final Color BACKGROUND = new Color(0f, 0f, 0f, 1f);
    private static final Color HUD_GREY = new Color(0.42f, 0.42f, 0.45f, 1f);
    private static final Color BOUNDARY = new Color(0.50f, 0.50f, 0.55f, 1f);
    private static final Color PLAYER_BLUE = new Color(0.12f, 0.35f, 0.95f, 1f);
    private static final Color ENEMY_RED = new Color(0.90f, 0.12f, 0.12f, 1f);
    private static final Color PROJECTILE_WHITE = new Color(1f, 1f, 1f, 1f);
    private static final Color DIM = new Color(0f, 0f, 0f, 0.62f);
    private static final Color PANEL = new Color(0.14f, 0.14f, 0.16f, 1f);
    private static final Color BORDER = new Color(0.72f, 0.72f, 0.75f, 1f);

    private final GladiatorArenaGame game;
    private final ArenaWorld world = new ArenaWorld();
    private final Rectangle restartButton = new Rectangle();
    private final Vector3 touch = new Vector3();

    public GameplayScreen(GladiatorArenaGame game) {
        this.game = game;
    }

    @Override
    public void render(float delta) {
        float dirX = 0f;
        float dirY = 0f;

        if (world.getState() == ArenaWorld.State.PLAYING) {
            if (Gdx.input.isKeyPressed(Input.Keys.W) || Gdx.input.isKeyPressed(Input.Keys.UP)) {
                dirY -= 1f;
            }
            if (Gdx.input.isKeyPressed(Input.Keys.S) || Gdx.input.isKeyPressed(Input.Keys.DOWN)) {
                dirY += 1f;
            }
            if (Gdx.input.isKeyPressed(Input.Keys.A) || Gdx.input.isKeyPressed(Input.Keys.LEFT)) {
                dirX -= 1f;
            }
            if (Gdx.input.isKeyPressed(Input.Keys.D) || Gdx.input.isKeyPressed(Input.Keys.RIGHT)) {
                dirX += 1f;
            }
            if (Gdx.input.justTouched()) {
                game.camera.unproject(touch.set(Gdx.input.getX(), Gdx.input.getY(), 0f));
                world.shoot(touch.x, touch.y);
            }
        } else {
            computeRestartButton();
            if (Gdx.input.justTouched()) {
                game.camera.unproject(touch.set(Gdx.input.getX(), Gdx.input.getY(), 0f));
                if (restartButton.contains(touch.x, touch.y)) {
                    world.reset();
                }
            }
        }

        world.update(delta, dirX, dirY);
        draw();
    }

    private void computeRestartButton() {
        game.centeredBounds(restartLabel(), 24f, 640f, 430f, 34f, 16f, restartButton);
    }

    private String restartLabel() {
        return world.getState() == ArenaWorld.State.WON ? "PLAY AGAIN" : "RETRY";
    }

    private void draw() {
        ScreenUtils.clear(BACKGROUND);
        ShapeRenderer s = game.shapes;
        s.setProjectionMatrix(game.camera.combined);

        // Arena boundary ring.
        s.begin(ShapeRenderer.ShapeType.Line);
        s.setColor(BOUNDARY);
        s.circle(ArenaWorld.ARENA_CX, ArenaWorld.ARENA_CY, ArenaWorld.ARENA_R, 96);
        s.end();

        // HUD bar + entities.
        s.begin(ShapeRenderer.ShapeType.Filled);
        s.setColor(HUD_GREY);
        s.rect(0f, 0f, ArenaWorld.WIDTH, 40f);

        s.setColor(ENEMY_RED);
        Array<Enemy> enemies = world.getEnemies();
        for (int i = 0; i < enemies.size; i++) {
            Enemy e = enemies.get(i);
            s.circle(e.x, e.y, ArenaWorld.ENEMY_RADIUS, 20);
        }

        s.setColor(PLAYER_BLUE);
        s.circle(world.getPlayerX(), world.getPlayerY(), ArenaWorld.PLAYER_RADIUS, 28);

        s.setColor(PROJECTILE_WHITE);
        Array<Projectile> projectiles = world.getProjectiles();
        for (int i = 0; i < projectiles.size; i++) {
            Projectile p = projectiles.get(i);
            s.circle(p.x, p.y, ArenaWorld.PROJECTILE_RADIUS, 12);
        }
        s.end();

        boolean ended = world.getState() != ArenaWorld.State.PLAYING;
        if (ended) {
            computeRestartButton();
            Gdx.gl.glEnable(GL20.GL_BLEND);
            s.begin(ShapeRenderer.ShapeType.Filled);
            s.setColor(DIM);
            s.rect(0f, 0f, ArenaWorld.WIDTH, ArenaWorld.HEIGHT);
            s.setColor(BORDER);
            s.rect(restartButton.x, restartButton.y, restartButton.width, restartButton.height);
            s.setColor(PANEL);
            s.rect(restartButton.x + 2f, restartButton.y + 2f, restartButton.width - 4f, restartButton.height - 4f);
            s.end();
        }

        game.batch.setProjectionMatrix(game.camera.combined);
        game.batch.begin();
        game.drawLeft("HEALTH: " + world.getPlayerHp(), 20f, 14f, 20f, Color.WHITE);
        game.drawRight("WAVE: " + world.getWave(), 20f, ArenaWorld.WIDTH - 14f, 20f, Color.WHITE);
        if (ended) {
            String title = world.getState() == ArenaWorld.State.WON ? "GLADIATOR ARENA CHAMPION" : "GLADIATOR DEFEATED";
            game.drawCentered(title, 48f, 640f, 300f, Color.WHITE);
            game.drawCentered("FINAL SCORE: " + world.getScore(), 30f, 640f, 365f, Color.WHITE);
            game.drawCentered(restartLabel(), 24f, 640f, 430f, Color.WHITE);
        }
        game.batch.end();
    }
}
