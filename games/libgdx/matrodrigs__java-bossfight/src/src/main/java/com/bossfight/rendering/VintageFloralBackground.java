package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Disposable;
import com.bossfight.boss.Boss;
import com.bossfight.config.Constants;

public class VintageFloralBackground implements Disposable {
    private static final String ROOT = "sprites/background/floral_vintage/";

    private final Layer[] backLayers;
    private final Layer[] foregroundLayers;

    private record Layer(
            Texture texture,
            float x,
            float y,
            float width,
            float height,
            float parallax,
            float alpha
    ) {
    }

    private record SceneMood(float phaseIntensity, float elapsed, float sway) {
    }

    public VintageFloralBackground() {
        backLayers = new Layer[] {
                layer("sky/sky_wash.png", -40f, -26f, Constants.WORLD_WIDTH + 80f,
                        Constants.WORLD_HEIGHT + 56f, 0.02f, 1f),
                layer("horizon/far_hills.png", 84f, 160f, 1120f, 244f, 0.12f, 0.78f),
                layer("horizon/distant_garden.png", -18f, 100f, 1320f, 172f, 0.24f, 0.78f),
                layer("midground/tree_left_canopy.png", -12f, 100f, 240f, 370f, 0.38f, 0.84f),
                layer("midground/tree_right_trunk.png", 1034f, 42f, 264f, 390f, 0.48f, 0.96f),
                layer("midground/shrub_cluster_a.png", 175f, 98f, 310f, 92f, 0.58f, 0.74f),
                layer("midground/shrub_cluster_b.png", 535f, 99f, 220f, 112f, 0.6f, 0.78f),
                layer("midground/shrub_cluster_c.png", 792f, 98f, 340f, 118f, 0.62f, 0.8f),
                layer("ground/ground_main.png", -40f, -20f, 1350f, 168f, 0.86f, 1f),
                layer("ground/ground_edge_left.png", -50f, -10f, 160f, 178f, 0.88f, 1f),
                layer("ground/ground_edge_right.png", 1160f, -10f, 160f, 156f, 0.88f, 1f),
                layer("decor/flower_cluster_warm.png", 235f, 64f, 140f, 78f, 0.9f, 0.95f),
                layer("decor/flower_cluster_daisy.png", 610f, 64f, 150f, 70f, 0.9f, 0.95f)
        };
        foregroundLayers = new Layer[] {
                layer("foreground/fg_foliage_left.png", -20f, -44f, 370f, 168f, 1.08f, 0.96f),
                layer("foreground/fg_foliage_center.png", 420f, -46f, 380f, 154f, 1.08f, 0.94f),
                layer("foreground/fg_foliage_right.png", 890f, -44f, 390f, 154f, 1.08f, 0.96f)
        };
    }

    public void renderBack(SpriteBatch batch, OrthographicCamera camera, Boss boss, float elapsed) {
        batch.setProjectionMatrix(camera.combined);
        batch.begin();

        drawLayers(batch, camera, backLayers, sceneMood(boss, elapsed, 0f));

        batch.setColor(Color.WHITE);
        batch.end();
    }

    public void renderForeground(SpriteBatch batch, OrthographicCamera camera, Boss boss, float elapsed) {
        batch.setProjectionMatrix(camera.combined);
        batch.begin();

        float baseSway = boss.isFinalRage() ? 4.5f : boss.isPhaseTwo() ? 2.4f : 0.8f;
        drawLayers(batch, camera, foregroundLayers,
                sceneMood(boss, elapsed, baseSway + boss.getActionImpulse() * 4f));

        batch.setColor(Color.WHITE);
        batch.end();
    }

    private Layer layer(String relativePath, float x, float y, float width, float height,
                        float parallax, float alpha) {
        return new Layer(TextureLoader.loadLinear(ROOT + relativePath),
                x, y, width, height, parallax, alpha);
    }

    private SceneMood sceneMood(Boss boss, float elapsed, float sway) {
        float phaseIntensity = boss.isFinalRage() ? 1f : boss.isPhaseTwo() ? 0.55f : 0f;
        return new SceneMood(phaseIntensity, elapsed, sway);
    }

    private void drawLayers(SpriteBatch batch, OrthographicCamera camera, Layer[] layers, SceneMood mood) {
        for (Layer layer : layers) {
            drawParallax(batch, camera, layer, mood);
        }
    }

    private void drawParallax(SpriteBatch batch, OrthographicCamera camera, Layer layer, SceneMood mood) {
        float cameraDeltaX = camera.position.x - Constants.WORLD_WIDTH * 0.5f;
        float cameraDeltaY = camera.position.y - Constants.WORLD_HEIGHT * 0.5f;
        float drawX = layer.x() + cameraDeltaX * (1f - layer.parallax());
        float layerSway = MathUtils.sin(mood.elapsed() * 2f + layer.x() * 0.012f) * mood.sway();
        float drawY = layer.y() + cameraDeltaY * (1f - layer.parallax()) + layerSway;
        batch.setColor(1f,
                1f - mood.phaseIntensity() * 0.12f,
                1f - mood.phaseIntensity() * 0.20f,
                layer.alpha());
        batch.draw(layer.texture(), drawX, drawY, layer.width(), layer.height());
    }

    @Override
    public void dispose() {
        disposeLayers(backLayers);
        disposeLayers(foregroundLayers);
    }

    private void disposeLayers(Layer[] layers) {
        for (Layer layer : layers) {
            layer.texture().dispose();
        }
    }
}
