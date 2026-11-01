package com.micro1.mooncourier;

import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.utils.Disposable;

import java.util.Random;

/**
 * Shared, GL-backed presentation resources: four sizes of the built-in {@code BitmapFont} (asset-free
 * - no font file is shipped, the glyphs come from the gdx jar), a reusable {@link GlyphLayout}, and
 * fixed procedural star / regolith-speckle fields so the background does not shimmer frame to frame.
 * Created once by {@link MoonCourierGame} after the GL context exists and disposed with it.
 */
public final class Assets implements Disposable {

    public final BitmapFont fontTitle;   // big splash titles
    public final BitmapFont fontHeading; // section headers, buttons
    public final BitmapFont fontLabel;   // HUD labels, result rows
    public final BitmapFont fontSmall;   // fine print, controls
    public final GlyphLayout layout = new GlyphLayout();

    /** Star field for the space backgrounds: triples of x, y (in 1280x720 space) and brightness. */
    public final float[] stars;
    /** Regolith speckles for the gameplay surface: triples of x, y and a 0/1 light-or-dark flag. */
    public final float[] speckles;

    public Assets() {
        fontTitle = makeFont(3.1f);
        fontHeading = makeFont(1.7f);
        fontLabel = makeFont(1.15f);
        fontSmall = makeFont(0.95f);

        Random rng = new Random(20260714L);
        stars = new float[150 * 3];
        for (int i = 0; i < 150; i++) {
            stars[i * 3] = rng.nextFloat() * 1280f;
            stars[i * 3 + 1] = 260f + rng.nextFloat() * 460f; // upper space band
            stars[i * 3 + 2] = 0.35f + rng.nextFloat() * 0.65f;
        }
        speckles = new float[240 * 3];
        for (int i = 0; i < 240; i++) {
            speckles[i * 3] = rng.nextFloat() * 1280f;
            speckles[i * 3 + 1] = rng.nextFloat() * 720f;
            speckles[i * 3 + 2] = rng.nextBoolean() ? 1f : 0f;
        }
    }

    private static BitmapFont makeFont(float scale) {
        BitmapFont font = new BitmapFont();
        font.getData().setScale(scale);
        font.setUseIntegerPositions(false);
        font.getRegion().getTexture().setFilter(TextureFilter.Linear, TextureFilter.Linear);
        return font;
    }

    @Override
    public void dispose() {
        fontTitle.dispose();
        fontHeading.dispose();
        fontLabel.dispose();
        fontSmall.dispose();
    }
}
