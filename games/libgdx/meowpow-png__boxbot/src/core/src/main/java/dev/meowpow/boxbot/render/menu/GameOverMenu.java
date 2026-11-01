package dev.meowpow.boxbot.render.menu;

/**
 * Holds the game-over menu
 * visibility and selection state.
 */
public final class GameOverMenu {

    private final MenuSelection selection;

    private boolean open;

    public GameOverMenu() {
        this.selection = new MenuSelection(GameOverMenuLabel.values());
    }

    /**
     * Opens the game-over menu with Try Again selected.
     *
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void open(MenuRenderer renderer) {
        open = true;
        selection.hover(GameOverMenuLabel.TRY_AGAIN, renderer);
    }

    /**
     * Closes the game-over menu.
     */
    public void close() {
        open = false;
    }

    /**
     * Returns whether the game-over menu is currently visible.
     *
     * @return whether the menu is open
     */
    public boolean isOpen() {
        return open;
    }

    /**
     * Returns the game-over menu's selection.
     */
    public MenuSelection selection() {
        return selection;
    }
}
