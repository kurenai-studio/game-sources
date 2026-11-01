package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.GameAction;
import dev.meowpow.boxbot.input.WorldClick;
import dev.meowpow.boxbot.input.WorldHover;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Controls the in-game game-over menu.
 */
@HotPath
public final class GameOverController {

    private final GameOverMenu gameOverMenu = new GameOverMenu();
    private final Runnable tryAgain;
    private final Runnable returnToMainMenu;

    /**
     * @throws NullPointerException if {@code tryAgain} or {@code returnToMainMenu} is null
     */
    public GameOverController(Runnable tryAgain, Runnable returnToMainMenu) {
        Objects.requireNonNull(tryAgain, "tryAgain must not be null");
        Objects.requireNonNull(returnToMainMenu, "returnToMainMenu must not be null");

        this.tryAgain = tryAgain;
        this.returnToMainMenu = returnToMainMenu;
    }

    /**
     * Returns whether the game-over menu is currently open.
     */
    public boolean isOpen() {
        return gameOverMenu.isOpen();
    }

    /**
     * Returns the game-over menu's currently selected item, if any.
     */
    public @Nullable MenuLabel selectedLabel() {
        return gameOverMenu.selection().selected();
    }

    /**
     * Closes the game-over menu.
     */
    public void close() {
        gameOverMenu.close();
    }

    /**
     * Opens the game-over menu with {@code Try Again} selected.
     *
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void open(MenuRenderer renderer) {
        gameOverMenu.open(renderer);
    }

    /**
     * Handles a menu-navigation action.
     *
     * @param action the action to handle
     * @param renderer the renderer whose currently enabled items constrain selection
     */
    public void handleAction(GameAction action, MenuRenderer renderer) {
        switch (action) {
            case MENU_SELECT_PREVIOUS -> gameOverMenu.selection().move(-1, renderer);
            case MENU_SELECT_NEXT -> gameOverMenu.selection().move(1, renderer);
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
        gameOverMenu.selection().hover(label, renderer);
        if (gameOverMenu.selection().selected() != null) {
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
        gameOverMenu.selection().hover(label, renderer);
    }

    private void activateSelection(MenuRenderer renderer) {
        var label = gameOverMenu.selection().selected();
        if (label == null || !renderer.isEnabled(label)) {
            return;
        }
        switch ((GameOverMenuLabel) label) {
            case TRY_AGAIN -> {
                gameOverMenu.close();
                tryAgain.run();
            }
            case MAIN_MENU -> returnToMainMenu.run();
        }
    }
}
