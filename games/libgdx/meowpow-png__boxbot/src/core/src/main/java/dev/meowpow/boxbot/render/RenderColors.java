package dev.meowpow.boxbot.render;

import com.badlogic.gdx.graphics.Color;

/**
 * Color tokens shared across the game's renderers.
 */
public final class RenderColors {

    /**
     * Accent color for HUD headers and world-space label text.
     */
    public static final Color ACCENT = Color.valueOf("D8B400");

    /**
     * HUD panel body text color.
     */
    public static final Color HUD_PANEL_BODY_FONT = Color.valueOf("CCCCCC");

    /**
     * HUD panel background fill color.
     */
    public static final Color HUD_PANEL_FILL = Color.valueOf("111418");

    /**
     * HUD panel border color.
     */
    public static final Color HUD_PANEL_BORDER = Color.valueOf("4D4D4D");

    /**
     * Menu panel background fill color.
     */
    public static final Color MENU_PANEL_FILL = new Color(0.07f, 0.08f, 0.09f, 0.9f);

    /**
     * Menu panel background fill color for buttons.
     */
    public static final Color MENU_PANEL_FILL_BUTTON = new Color(0.07f, 0.08f, 0.09f, 0.9f);

    /**
     * Menu panel border color for outer edges.
     */
    public static final Color MENU_PANEL_BORDER_OUTER = new Color(0.3f, 0.3f, 0.3f, 0.2f);

    /**
     * Menu panel border color for buttons.
     */
    public static final Color MENU_PANEL_BORDER_BUTTON = new Color(0.3f, 0.3f, 0.3f, 8f);

    /**
     * Translucent overlay drawn behind the main menu screen.
     */
    public static final Color MAIN_MENU_DIM_OVERLAY = new Color(0f, 0f, 0f, 0.2f);

    /**
     * Translucent overlay drawn behind the pause menu screen.
     */
    public static final Color PAUSE_MENU_DIM_OVERLAY = new Color(0f, 0f, 0f, 0.2f);

    /**
     * Text color for unavailable menu items.
     */
    public static final Color MENU_DISABLED_TEXT = new Color(0.45f, 0.45f, 0.45f, 1f);

    /**
     * HUD scroll list scrollbar thumb color.
     */
    public static final Color SCROLLBAR = Color.valueOf("FFFFFF");

    /**
     * Robot panel battery bar fill color.
     */
    public static final Color BATTERY_FILL = Color.valueOf("59D966");

    /**
     * Robot panel battery bar track color.
     */
    public static final Color BATTERY_TRACK = Color.valueOf("404047");

    /**
     * Red package text color.
     */
    public static final Color PACKAGE_RED = Color.valueOf("E0605C");

    /**
     * Green package text color.
     */
    public static final Color PACKAGE_GREEN = Color.valueOf("5CC96B");

    /**
     * Blue package text color.
     */
    public static final Color PACKAGE_BLUE = Color.valueOf("5C8FE0");

    /**
     * Primary selection rectangle color.
     */
    public static final Color SELECTION_PRIMARY = Color.valueOf("FFFFFF");

    /**
     * Secondary selection rectangle color.
     */
    public static final Color SELECTION_SECONDARY = Color.valueOf("5CE1E6");

    /**
     * Queued pair source primary rectangle color.
     */
    public static final Color SELECTION_QUEUED_PRIMARY = Color.valueOf("9C47E6");

    /**
     * Queued pair destination secondary rectangle color.
     */
    public static final Color SELECTION_QUEUED_SECONDARY = Color.valueOf("E667C4");

    /**
     * Orders panel ETA text color once an order nears its deadline.
     */
    public static final Color ORDER_WARNING = Color.valueOf("E6A33D");

    /**
     * Orders panel ETA text color once an order is close to expiring.
     */
    public static final Color ORDER_CRITICAL = Color.valueOf("E0605C");

    private RenderColors() {}
}
