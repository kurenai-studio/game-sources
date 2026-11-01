package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.g2d.Batch;

/**
 * The dungeon's ambient light, drawn behind every screen: a warm torch glow
 * over a darkening vignette, both procedural textures from the {@link Theme}.
 * Purely decorative and never a hit target.
 *
 * <p>It is a plain object the screens advance and draw themselves.
 */
final class Backdrop {

    // The glow, centred a little above the world middle like an overhead torch.
    private static final float GLOW_SIZE = 1180f;
    private static final float GLOW_Y_OFFSET = 40f;
    private static final float GLOW_ALPHA = 0.16f;

    private final Theme theme;
    private final Embers embers = new Embers(1337);
    private float elapsed;

    /**
     * A backdrop with its own embers, seeded the same every time.
     *
     * @param theme where the glow, vignette and ember textures come from
     */
    Backdrop(Theme theme) {
        this.theme = theme;
    }

    /**
     * Moves the flicker and the embers on.
     *
     * @param delta seconds since the last frame
     */
    void advance(float delta) {
        elapsed += delta;
        embers.update(delta);
    }

    /**
     * Draws straight onto a batch — the screens are drawn in immediate mode and
     * need their backdrop under them, not over them.
     *
     * @param batch the screen's batch, already begun; its colour is left white
     * @param light how alive the fire is; 1 normally, near zero once it is snuffed
     *              by a death, which dims the glow and the embers but not the
     *              vignette, so the dark stays while the fire goes out
     */
    void render(Batch batch, float light) {
        float gx = (Theme.WORLD_WIDTH - GLOW_SIZE) / 2f;
        float gy = (Theme.WORLD_HEIGHT - GLOW_SIZE) / 2f + GLOW_Y_OFFSET;
        float glowAlpha = GLOW_ALPHA * TorchFlicker.intensityAt(elapsed) * light;
        batch.setColor(Theme.TORCHLIGHT.r, Theme.TORCHLIGHT.g, Theme.TORCHLIGHT.b, glowAlpha);
        batch.draw(theme.glowRegion(), gx, gy, GLOW_SIZE, GLOW_SIZE);

        batch.setColor(1f, 1f, 1f, 1f);
        batch.draw(theme.vignetteRegion(), 0, 0, Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);

        // Drifting embers, over the vignette so they still glow in the dark corners.
        for (Embers.Ember e : embers.particles()) {
            batch.setColor(Theme.TORCHLIGHT.r, Theme.TORCHLIGHT.g, Theme.TORCHLIGHT.b, e.alpha * light);
            batch.draw(theme.dotRegion(), e.x - e.size / 2f, e.y - e.size / 2f, e.size, e.size);
        }
        // Leave the batch colour as we found it for the actors drawn on top.
        batch.setColor(1f, 1f, 1f, 1f);
    }
}
