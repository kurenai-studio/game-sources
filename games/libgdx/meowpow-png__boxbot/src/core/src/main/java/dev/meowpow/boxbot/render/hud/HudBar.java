package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

import java.util.Objects;

/**
 * Represents a HUD segmented fill meter.
 */
@HotPath
public final class HudBar {

    private final Color fillColor;
    private final Color trackColor;
    private final int segmentCount;
    private final float segmentGap;

    /**
     * Creates a bar with the given fill and track colors,
     * divided into the given number of segments.
     *
     * @param fillColor the color of a lit segment
     * @param trackColor the color of an unlit segment
     * @param segmentCount the number of segments the bar is divided into
     * @param segmentGap the spacing between adjacent segments, in world units
     *
     * @throws NullPointerException if {@code fillColor} or {@code trackColor} is null
     * @throws IllegalArgumentException if {@code segmentCount}
     * is not positive, or {@code segmentGap} is negative
     */
    public HudBar(Color fillColor, Color trackColor, int segmentCount, float segmentGap) {
        this.fillColor = Objects.requireNonNull(fillColor, "fillColor must not be null");
        this.trackColor = Objects.requireNonNull(trackColor, "trackColor must not be null");
        if (segmentCount <= 0) {
            throw new IllegalArgumentException("segmentCount must be positive: " + segmentCount);
        }
        if (segmentGap < 0f) {
            throw new IllegalArgumentException("segmentGap must not be negative: " + segmentGap);
        }
        this.segmentCount = segmentCount;
        this.segmentGap = segmentGap;
    }

    /**
     * Draws the bar at the given position, lighting
     * the number of segments proportional to {@code fill}.
     *
     * @param renderer the shape renderer to draw into
     * @param x the bar's left edge, in world units
     * @param y the bar's bottom edge, in world units
     * @param width the bar's full width, in world units
     * @param height the bar's height, in world units
     * @param fill the filled fraction, clamped to [0, 1]
     */
    public void render(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height,
            float fill
    ) {
        float clampedFill = Math.clamp(fill, 0f, 1f);
        int litSegments = clampedFill <= 0f ? 0 : (int) Math.ceil(clampedFill * segmentCount);

        float totalGap = segmentGap * (segmentCount - 1);
        float segmentWidth = (width - totalGap) / segmentCount;

        for (int i = 0; i < segmentCount; i++) {
            renderer.setColor(i < litSegments ? fillColor : trackColor);
            renderer.rect(x + i * (segmentWidth + segmentGap), y, segmentWidth, height);
        }
    }
}
