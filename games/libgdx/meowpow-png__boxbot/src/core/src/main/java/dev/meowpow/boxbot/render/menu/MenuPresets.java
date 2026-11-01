package dev.meowpow.boxbot.render.menu;

/**
 * The game's named menu geometries.
 */
public final class MenuPresets {

    private MenuPresets() {}

    /**
     * The standard menu geometry,
     * used by the main menu and pause menu.
     */
    public static final MenuPreset STANDARD = new MenuPreset(
            260f,
            34f,
            12f
    );

    /**
     * The game-over menu's geometry.
     */
    public static final MenuPreset GAME_OVER = new MenuPreset(
            300f,
            34f,
            18f
    );
}
