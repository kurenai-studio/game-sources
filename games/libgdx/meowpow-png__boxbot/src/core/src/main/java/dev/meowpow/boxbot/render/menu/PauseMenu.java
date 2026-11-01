package dev.meowpow.boxbot.render.menu;

/**
 * Holds the in-game pause menu
 * visibility and selection state.
 */
public final class PauseMenu {

    private final MenuSelection selection;

    private boolean open;

    public PauseMenu() {
        this.selection = new MenuSelection(PauseMenuLabel.values());
    }

    /**
     * Opens the pause menu with Resume selected.
     *
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void open(MenuRenderer renderer) {
        open = true;
        selection.hover(PauseMenuLabel.RESUME, renderer);
    }

    /**
     * Closes the pause menu.
     */
    public void close() {
        open = false;
    }

    /**
     * Returns whether the pause menu is currently visible.
     *
     * @return whether the menu is open
     */
    public boolean isOpen() {
        return open;
    }

    /**
     * Returns the pause menu's selection.
     */
    public MenuSelection selection() {
        return selection;
    }
}
