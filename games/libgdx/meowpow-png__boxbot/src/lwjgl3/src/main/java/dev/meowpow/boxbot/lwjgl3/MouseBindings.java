package dev.meowpow.boxbot.lwjgl3;

import dev.meowpow.boxbot.input.*;

import com.badlogic.gdx.Input.Buttons;
import com.badlogic.gdx.InputAdapter;

/**
 * Translates mouse inputs into game actions.
 */
public final class MouseBindings extends InputAdapter {

    private final GameActionDispatcher actionDispatcher;
    private final WorldClickDispatcher clickDispatcher;
    private final WorldHoverDispatcher hoverDispatcher;

    private final WorldHover hover = new WorldHover();

    /**
     * Creates the bindings with the given
     * dispatchers that react to mouse events.
     *
     * @param actionDispatcher the dispatcher to raise actions on
     * @param clickDispatcher the dispatcher to raise clicks on
     * @param hoverDispatcher the dispatcher to raise hovers on
     */
    public MouseBindings(
            GameActionDispatcher actionDispatcher,
            WorldClickDispatcher clickDispatcher,
            WorldHoverDispatcher hoverDispatcher
    ) {
        this.actionDispatcher = actionDispatcher;
        this.clickDispatcher = clickDispatcher;
        this.hoverDispatcher = hoverDispatcher;
    }

    @Override
    public boolean scrolled(float amountX, float amountY) {
        if (amountY < 0) {
            return dispatch(GameAction.SCROLL_PANEL_UP);
        }
        if (amountY > 0) {
            return dispatch(GameAction.SCROLL_PANEL_DOWN);
        }
        return false;
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        if (button != Buttons.LEFT) {
            return false;
        }
        clickDispatcher.dispatch(new WorldClick(screenX, screenY));
        return true;
    }

    @Override
    public boolean mouseMoved(int screenX, int screenY) {
        hover.set(screenX, screenY);
        hoverDispatcher.dispatch(hover);
        return false;
    }

    private boolean dispatch(GameAction action) {
        actionDispatcher.dispatch(action);
        return true;
    }
}
