package dev.meowpow.boxbot.render.screen;

import com.badlogic.gdx.math.Rectangle;

import java.util.Objects;

/**
 * Represents a screen preset for one of
 * the game's supported fixed window sizes.
 *
 * @param width the window's width, in pixels
 * @param height the window's height, in pixels
 * @param shell the shell's padded inset of the window
 * @param warehouse the warehouse world's region
 * @param hud the HUD panel's region
 * @param scale the integer pixel scale content renders at
 */
public record ScreenPreset(
        int width,
        int height,
        Rectangle shell,
        Rectangle warehouse,
        Rectangle hud,
        int scale
) {

    /**
     * @throws IllegalArgumentException if {@code width},
     * {@code height}, or {@code scale} is not positive
     * @throws NullPointerException if {@code shell},
     * {@code warehouse}, or {@code hud} is null
     */
    public ScreenPreset {
        if (width <= 0) {
            throw new IllegalArgumentException("width must be positive");
        }
        if (height <= 0) {
            throw new IllegalArgumentException("height must be positive");
        }
        if (scale <= 0) {
            throw new IllegalArgumentException("scale must be positive");
        }
        Objects.requireNonNull(shell, "shell must not be null");
        Objects.requireNonNull(warehouse, "warehouse must not be null");
        Objects.requireNonNull(hud, "hud must not be null");
    }
}
