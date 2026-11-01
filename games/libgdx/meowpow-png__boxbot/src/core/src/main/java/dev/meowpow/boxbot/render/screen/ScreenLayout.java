package dev.meowpow.boxbot.render.screen;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.math.Rectangle;

import java.util.List;

/**
 * Divides the window into regions the game renders into.
 */
public final class ScreenLayout {

    private final Rectangle shell = new Rectangle();
    private final Rectangle hud = new Rectangle();
    private final Rectangle warehouse = new Rectangle();

    private final List<ScreenPreset> windowedPresets;

    private int scale;

    /**
     * Creates the layout for the window's current size,
     * recognizing the given large preset and
     * {@link ScreenPresets#SMALL} as windowed sizes.
     *
     * @param large the larger windowed size this layout recognizes
     */
    public ScreenLayout(ScreenPreset large) {
        this(ScreenPresets.SMALL, large);
    }

    /**
     * Creates the layout for the window's current size,
     * recognizing the given small and large presets as windowed sizes.
     *
     * @param small the smaller windowed size this layout recognizes
     * @param large the larger windowed size this layout recognizes
     */
    public ScreenLayout(ScreenPreset small, ScreenPreset large) {
        windowedPresets = List.of(small, large);
        update(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
    }

    /**
     * Loads the display regions for the given window size.
     * <p>
     * This method will compute a fresh layout if it doesn't
     * match a windowed preset (as happens in fullscreen).
     *
     * @param screenWidth the window's width in pixels
     * @param screenHeight the window's height in pixels
     */
    public void update(int screenWidth, int screenHeight) {
        var preset = windowedPresets.stream()
                .filter(p -> p.width() == screenWidth && p.height() == screenHeight)
                .findFirst()
                .orElseGet(() -> ScreenPresets.compute(screenWidth, screenHeight));

        shell.set(preset.shell());
        warehouse.set(preset.warehouse());
        hud.set(preset.hud());
        scale = preset.scale();
    }

    /**
     * Returns the shell's padded inset of the window.
     */
    public Rectangle shell() {
        return shell;
    }

    /**
     * Returns the integer pixel scale content renders at.
     */
    public int scale() {
        return scale;
    }

    /**
     * Returns the HUD's screen bounds.
     */
    public Rectangle hud() {
        return hud;
    }

    /**
     * Returns the warehouse's screen bounds.
     */
    public Rectangle warehouse() {
        return warehouse;
    }
}
