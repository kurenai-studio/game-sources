package com.micro1.monstercafe;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;

/**
 * A clickable image: a {@link TextureRegion} drawn within on-screen bounds (world coordinates, y-up). The
 * bounds double as the click hit-box, so callers size the bounds to the visible art. Pure geometry + draw;
 * it does no input polling of its own (the owning screen polls and calls {@link #contains}).
 */
public class SpriteButton {
    private final TextureRegion region;
    public final Rectangle bounds = new Rectangle();

    public SpriteButton(TextureRegion region) {
        this.region = region;
    }

    /** Position by center, sized (w, h). */
    public SpriteButton setCentered(float cx, float cy, float w, float h) {
        bounds.set(cx - w / 2f, cy - h / 2f, w, h);
        return this;
    }

    /** Position by center, fixing the height and deriving the width from the region's aspect ratio. */
    public SpriteButton setCenteredByHeight(float cx, float cy, float h) {
        float w = h * region.getRegionWidth() / (float) region.getRegionHeight();
        return setCentered(cx, cy, w, h);
    }

    public void draw(SpriteBatch batch) {
        batch.draw(region, bounds.x, bounds.y, bounds.width, bounds.height);
    }

    public boolean contains(float x, float y) {
        return bounds.contains(x, y);
    }
}
