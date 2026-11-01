package com.micro1.projectileaiming;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * Render + input layer for the projectile-aiming prototype. All simulation and game-state rules
 * live in {@link AimingWorld}; this class polls the mouse, feeds the cursor (in world space) and
 * button state into the world each frame, and draws the world's state with {@link ShapeRenderer}
 * primitives plus a {@link BitmapFont} HUD. No textures, no external assets.
 */
public class ProjectileAimingApp extends ApplicationAdapter {

    // Render-only tuning (the world owns the physics/layout constants).
    private static final float TARGET_MID_R = 16f;
    private static final float TARGET_INNER_R = 9f;
    private static final float PREVIEW_DOT_RADIUS = 3f;

    private static final Color BACKGROUND = new Color(0.960f, 0.949f, 0.906f, 1f);
    private static final Color GROUND = new Color(0.804f, 0.678f, 0.522f, 1f);
    private static final Color LAUNCHER = new Color(0.267f, 0.278f, 0.302f, 1f);
    private static final Color PROJECTILE = new Color(0.129f, 0.129f, 0.145f, 1f);
    private static final Color PREVIEW_DOT = new Color(0.400f, 0.400f, 0.440f, 1f);
    private static final Color TARGET_RING = new Color(0.129f, 0.129f, 0.145f, 1f);
    private static final Color TARGET_WHITE = new Color(0.980f, 0.980f, 0.980f, 1f);
    private static final Color TARGET_RED = new Color(0.906f, 0.404f, 0.404f, 1f);
    private static final Color TARGET_GREEN = new Color(0.376f, 0.706f, 0.361f, 1f);
    private static final Color HUD_TEXT = new Color(0.149f, 0.149f, 0.180f, 1f);

    private final AimingWorld world = new AimingWorld();

    private Viewport viewport;
    private OrthographicCamera camera;
    private ShapeRenderer shapes;
    private SpriteBatch batch;
    private BitmapFont font;
    private GlyphLayout layout;

    private final Vector2 cursorWorld = new Vector2();

    @Override
    public void create() {
        camera = new OrthographicCamera();
        viewport = new FitViewport(AimingWorld.WORLD_W, AimingWorld.WORLD_H, camera);
        viewport.apply(true);

        shapes = new ShapeRenderer();
        batch = new SpriteBatch();
        font = new BitmapFont();
        font.getData().setScale(1.4f); // keep HUD glyph height well above the 14 px floor
        font.setColor(HUD_TEXT);
        layout = new GlyphLayout();
    }

    @Override
    public void render() {
        boolean pressed = Gdx.input.isButtonPressed(Input.Buttons.LEFT);
        viewport.unproject(cursorWorld.set(Gdx.input.getX(), Gdx.input.getY()));
        world.update(Gdx.graphics.getDeltaTime(), pressed, cursorWorld.x, cursorWorld.y);
        draw();
    }

    private void draw() {
        ScreenUtils.clear(BACKGROUND);
        viewport.apply();
        camera.update();

        shapes.setProjectionMatrix(camera.combined);
        shapes.begin(ShapeRenderer.ShapeType.Filled);

        shapes.setColor(GROUND);
        shapes.rect(0f, 0f, AimingWorld.WORLD_W, AimingWorld.GROUND_TOP);

        drawLauncher();

        Array<Target> targets = world.getTargets();
        for (int i = 0; i < targets.size; i++) {
            drawTarget(targets.get(i));
        }

        if (world.isAiming()) {
            shapes.setColor(PREVIEW_DOT);
            Array<Vector2> dots = world.getPreviewDots();
            for (int i = 0; i < dots.size; i++) {
                Vector2 p = dots.get(i);
                shapes.circle(p.x, p.y, PREVIEW_DOT_RADIUS, 10);
            }
        }

        if (world.isProjectileActive()) {
            shapes.setColor(PROJECTILE);
            Vector2 p = world.getProjectile().position;
            shapes.circle(p.x, p.y, AimingWorld.PROJECTILE_RADIUS, 20);
        }

        shapes.end();

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        layout.setText(font, "Hits: " + world.getHits() + " / " + AimingWorld.TARGET_GOAL);
        font.draw(batch, layout, AimingWorld.WORLD_W - layout.width - 16f, AimingWorld.WORLD_H - 16f);
        batch.end();
    }

    private void drawLauncher() {
        shapes.setColor(LAUNCHER);
        float pivotX = AimingWorld.LAUNCH_X - 30f;
        float pivotY = 76f;
        shapes.rect(pivotX - 14f, AimingWorld.GROUND_TOP - 2f, 42f, 20f);       // carriage
        shapes.circle(pivotX, pivotY, 15f, 24);                                 // pivot hub
        shapes.rectLine(pivotX, pivotY, AimingWorld.LAUNCH_X, AimingWorld.LAUNCH_Y, 16f); // barrel
        shapes.circle(AimingWorld.LAUNCH_X, AimingWorld.LAUNCH_Y, 8f, 16);      // muzzle cap
    }

    private void drawTarget(Target t) {
        shapes.setColor(TARGET_RING);
        shapes.circle(t.x, t.y, t.radius, 28);
        shapes.setColor(TARGET_WHITE);
        shapes.circle(t.x, t.y, TARGET_MID_R, 28);
        shapes.setColor(t.hit ? TARGET_GREEN : TARGET_RED);
        shapes.circle(t.x, t.y, TARGET_INNER_R, 24);
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }

    @Override
    public void dispose() {
        if (shapes != null) {
            shapes.dispose();
        }
        if (batch != null) {
            batch.dispose();
        }
        if (font != null) {
            font.dispose();
        }
    }
}
