package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.GameAction;
import dev.meowpow.boxbot.input.WorldClick;
import dev.meowpow.boxbot.input.WorldHover;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.Gdx;

import java.util.Objects;

/**
 * Controls the in-game pause menu.
 */
@HotPath
public final class PauseMenuController {

    private final PauseMenu pauseMenu = new PauseMenu();
    private final Runnable returnToMainMenu;

    /**
     * @throws NullPointerException if {@code returnToMainMenu} is null
     */
    public PauseMenuController(Runnable returnToMainMenu) {
        Objects.requireNonNull(returnToMainMenu, "returnToMainMenu must not be null");
        this.returnToMainMenu = returnToMainMenu;
    }

    /**
     * Returns whether the pause menu is currently open.
     */
    public boolean isOpen() {
        return pauseMenu.isOpen();
    }

    /**
     * Returns the pause menu's currently selected item, if any.
     */
    public @Nullable MenuLabel selectedLabel() {
        return pauseMenu.selection().selected();
    }

    /**
     * Closes the pause menu.
     */
    public void close() {
        pauseMenu.close();
    }

    /**
     * Opens the pause menu if it's
     * closed or closes it if it's open.
     *
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void toggle(MenuRenderer renderer) {
        if (pauseMenu.isOpen()) {
            pauseMenu.close();
        }
        else {
            pauseMenu.open(renderer);
        }
    }

    /**
     * Handles a menu-navigation action.
     *
     * @param action the action to handle
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void handleAction(GameAction action, MenuRenderer renderer) {
        switch (action) {
            case MENU_SELECT_PREVIOUS -> pauseMenu.selection().move(-1, renderer);
            case MENU_SELECT_NEXT -> pauseMenu.selection().move(1, renderer);
            case MENU_ACTIVATE -> activateSelection(renderer);
            default -> {}
        }
    }

    /**
     * Selects and activates whichever item click landed on.
     *
     * @param click the click that occurred in screen coordinates
     * @param renderer the renderer whose hit-testing and enabled items apply
     */
    public void handleClick(WorldClick click, MenuRenderer renderer) {
        var label = renderer.labelAt(click.screenX(), click.screenY());
        if (label == null) {
            return;
        }
        pauseMenu.selection().hover(label, renderer);
        if (pauseMenu.selection().selected() != null) {
            activateSelection(renderer);
        }
    }

    /**
     * Selects whichever item the pointer is hovering over, if any.
     *
     * @param hover the pointer position in screen coordinates
     * @param renderer the renderer whose hit-testing and enabled items apply
     */
    public void handleHover(WorldHover hover, MenuRenderer renderer) {
        var label = renderer.labelAt(hover.screenX(), hover.screenY());
        pauseMenu.selection().hover(label, renderer);
    }

    private void activateSelection(MenuRenderer renderer) {
        var label = pauseMenu.selection().selected();
        if (label == null || !renderer.isEnabled(label)) {
            return;
        }
        switch ((PauseMenuLabel) label) {
            case RESUME -> pauseMenu.close();
            case MAIN_MENU -> returnToMainMenu.run();
            case EXIT -> Gdx.app.exit();
            default -> {}
        }
    }
}
