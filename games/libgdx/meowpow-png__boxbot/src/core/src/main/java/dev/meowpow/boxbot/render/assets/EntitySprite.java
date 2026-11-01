package dev.meowpow.boxbot.render.assets;

import com.badlogic.gdx.graphics.g2d.TextureRegion;

import java.util.Objects;

/**
 * A texture region rendered
 * at a size proportional to itself.
 *
 * @param region the source texture region
 * @param sizeRatio the scale applied to {@code region}'s width to compute the rendered size
 */
public record EntitySprite(TextureRegion region, float sizeRatio) {

    /**
     * @throws NullPointerException if {@code region} is null
     * @throws IllegalArgumentException if {@code sizeRatio} is not positive
     */
    public EntitySprite {
        Objects.requireNonNull(region, "region must not be null");
        if (Float.isNaN(sizeRatio) || sizeRatio <= 0) {
            throw new IllegalArgumentException("sizeRatio must be > 0, got " + sizeRatio);
        }
    }

    /**
     * Returns the sprite's rendered size
     * in pixels, applied to both width and height
     */
    public float size() {
        return region.getRegionWidth() * sizeRatio;
    }
}
