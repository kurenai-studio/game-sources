package dev.meowpow.boxbot.input;

/**
 * A player-triggerable intent, decoupled
 * from whatever input device raised it.
 */
public enum GameAction {
    /**
     * Moves the menu selection to the previous item.
     */
    MENU_SELECT_PREVIOUS,

    /**
     * Moves the menu selection to the next item.
     */
    MENU_SELECT_NEXT,

    /**
     * Activates the currently selected menu item.
     */
    MENU_ACTIVATE,

    /**
     * Starts a new game from the main menu.
     */
    MENU_NEW_GAME,

    /**
     * Opens the settings item from the main menu.
     */
    MENU_SETTINGS,

    /**
     * Requests the active screen's back action.
     */
    MENU_BACK,

    /**
     * Switches between windowed
     * and fullscreen display.
     */
    TOGGLE_FULLSCREEN,

    /**
     * Reloads the game's rendering
     * assets and config from disk.
     */
    RELOAD_RESOURCES,

    /**
     * Restarts the level, rebuilding the
     * simulation from the currently loaded config.
     */
    RELOAD_LEVEL,

    /**
     * Scrolls the HUD panel toward earlier rows.
     */
    SCROLL_PANEL_UP,

    /**
     * Scrolls the HUD panel toward later rows.
     */
    SCROLL_PANEL_DOWN
}
