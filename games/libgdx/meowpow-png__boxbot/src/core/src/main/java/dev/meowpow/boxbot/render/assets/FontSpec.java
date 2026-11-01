package dev.meowpow.boxbot.render.assets;

import com.badlogic.gdx.graphics.Color;

import java.util.Objects;

/**
 * Represents font specifications,
 * used to bake a font from a font source.
 *
 * @param family the font source to bake from
 * @param size the font size in pixels
 * @param color the color to bake into the generated glyphs
 * @param borderWidth the border thickness in pixels, or {@code 0} for none
 * @param letterSpacing extra horizontal space between letters, in pixels, or {@code 0} for none
 */
public record FontSpec(
        FontFamily family,
        int size,
        Color color,
        float borderWidth,
        float letterSpacing
) {

    /**
     * @throws NullPointerException if {@code family} or {@code color} is null
     * @throws IllegalArgumentException if {@code size} is not positive,
     * or {@code borderWidth} or {@code letterSpacing} is negative
     */
    public FontSpec {
        Objects.requireNonNull(family, "family must not be null");
        Objects.requireNonNull(color, "color must not be null");
        if (size <= 0) {
            var message = "size must be positive: " + size;
            throw new IllegalArgumentException(message);
        }
        if (borderWidth < 0f) {
            var message = "borderWidth must not be negative: " + borderWidth;
            throw new IllegalArgumentException(message);
        }
        if (letterSpacing < 0f) {
            var message = "letterSpacing must not be negative: " + letterSpacing;
            throw new IllegalArgumentException(message);
        }
    }

    /**
     * Creates a spec with no border or letter spacing.
     *
     * @param family the font source to bake from
     * @param size the font size in pixels
     * @param color the color to bake into the generated glyphs
     */
    public static FontSpec of(FontFamily family, int size, Color color) {
        return new FontSpec(family, size, color, 0f, 0f);
    }
}
