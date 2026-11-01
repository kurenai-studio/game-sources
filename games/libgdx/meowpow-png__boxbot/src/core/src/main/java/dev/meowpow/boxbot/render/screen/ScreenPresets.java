package dev.meowpow.boxbot.render.screen;

import com.badlogic.gdx.math.Rectangle;

/**
 * The game's supported window sizes
 * and how each one lays out its regions.
 */
public final class ScreenPresets {

    private static final float WORLD_WIDTH = 640f;
    private static final float WORLD_HEIGHT = 480f;
    private static final float HUD_WIDTH_RATIO = 0.20f;
    private static final float PADDING_X_RATIO = 0.05f;
    private static final float PADDING_Y_RATIO = 0.02f;
    private static final float HUD_GAP_RATIO = 0.007f;

    private ScreenPresets() {}

    public static final ScreenPreset SMALL = new ScreenPreset(
            800, 480,
            new Rectangle(0, 0, 800, 480),
            new Rectangle(0, 0, 640, 480),
            new Rectangle(640, 0, 160, 480),
            1
    );

    /**
     * Computes a preset that fits the warehouse world as
     * large as possible, at its correct integer pixel scale,
     * centered with the HUD panel within the given window size.
     *
     * @param width the window's width, in pixels
     * @param height the window's height, in pixels
     *
     * @throws IllegalArgumentException if width or height is not positive
     */
    public static ScreenPreset compute(int width, int height) {
        int paddingX = Math.round(width * PADDING_X_RATIO);
        int paddingY = Math.round(height * PADDING_Y_RATIO);
        int hudGap = Math.round(width * HUD_GAP_RATIO);

        float shellWidth = width - 2f * paddingX;
        float shellHeight = height - 2f * paddingY;

        float availableForWorld = shellWidth * (1f - HUD_WIDTH_RATIO) - hudGap;
        int scale = integerScale(availableForWorld, shellHeight);

        float worldWidth = WORLD_WIDTH * scale;
        float worldHeight = WORLD_HEIGHT * scale;
        float hudWidth = shellWidth * HUD_WIDTH_RATIO;

        float contentWidth = worldWidth + hudGap + hudWidth;
        int warehouseX = Math.round(paddingX + (shellWidth - contentWidth) / 2f);
        int warehouseY = Math.round(paddingY + (shellHeight - worldHeight) / 2f);
        int hudX = Math.round(warehouseX + worldWidth + hudGap);

        var shell = new Rectangle(paddingX, paddingY, shellWidth, shellHeight);
        var warehouse = new Rectangle(warehouseX, warehouseY, worldWidth, worldHeight);
        var hud = new Rectangle(hudX, warehouseY, hudWidth, worldHeight);

        return new ScreenPreset(width, height, shell, warehouse, hud, scale);
    }

    /**
     * Computes a preset that fits the warehouse world as
     * large as possible, at its correct integer pixel scale,
     * centered in the window with no HUD panel.
     *
     * @param width the window's width, in pixels
     * @param height the window's height, in pixels
     *
     * @throws IllegalArgumentException if width or height is not positive
     */
    public static ScreenPreset computeCentered(int width, int height) {
        int paddingX = Math.round(width * PADDING_X_RATIO);
        int paddingY = Math.round(height * PADDING_Y_RATIO);

        float shellWidth = width - 2f * paddingX;
        float shellHeight = height - 2f * paddingY;

        int scale = integerScale(shellWidth, shellHeight);

        float worldWidth = WORLD_WIDTH * scale;
        float worldHeight = WORLD_HEIGHT * scale;

        int warehouseX = Math.round(paddingX + (shellWidth - worldWidth) / 2f);
        int warehouseY = Math.round(paddingY + (shellHeight - worldHeight) / 2f);

        var shell = new Rectangle(paddingX, paddingY, shellWidth, shellHeight);
        var warehouse = new Rectangle(warehouseX, warehouseY, worldWidth, worldHeight);
        var hud = new Rectangle(warehouseX + worldWidth, warehouseY, 0, 0);

        return new ScreenPreset(width, height, shell, warehouse, hud, scale);
    }

    private static int integerScale(float availableWidth, float availableHeight) {
        float widthRatio = availableWidth / WORLD_WIDTH;
        float heightRatio = availableHeight / WORLD_HEIGHT;

        return Math.max(1, (int) Math.min(widthRatio, heightRatio));
    }
}
