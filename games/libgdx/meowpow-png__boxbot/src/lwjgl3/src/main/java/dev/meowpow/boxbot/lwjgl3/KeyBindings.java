package dev.meowpow.boxbot.lwjgl3;

import dev.meowpow.boxbot.input.GameAction;
import dev.meowpow.boxbot.input.GameActionDispatcher;

import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.InputAdapter;

/**
 * Translates key presses into {@link GameAction}s.
 */
public final class KeyBindings extends InputAdapter {

    private final GameActionDispatcher dispatcher;

    /**
     * Creates the bindings, dispatching to
     * {@code dispatcher} on a bound key press.
     *
     * @param dispatcher the dispatcher to raise actions on
     */
    public KeyBindings(GameActionDispatcher dispatcher) {
        this.dispatcher = dispatcher;
    }

    @Override
    public boolean keyDown(int keycode) {
        return switch (keycode) {
            case Keys.UP -> dispatch(GameAction.MENU_SELECT_PREVIOUS);
            case Keys.DOWN -> dispatch(GameAction.MENU_SELECT_NEXT);
            case Keys.ENTER, Keys.SPACE -> dispatch(GameAction.MENU_ACTIVATE);
            case Keys.N -> dispatch(GameAction.MENU_NEW_GAME);
            case Keys.S -> dispatch(GameAction.MENU_SETTINGS);
            case Keys.ESCAPE -> dispatch(GameAction.MENU_BACK);
            case Keys.F5 -> dispatch(GameAction.RELOAD_RESOURCES);
            case Keys.F6 -> dispatch(GameAction.RELOAD_LEVEL);
            case Keys.F11 -> dispatch(GameAction.TOGGLE_FULLSCREEN);
            default -> false;
        };
    }

    private boolean dispatch(GameAction action) {
        dispatcher.dispatch(action);
        return true;
    }
}
