package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Input;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.Stage;
import java.util.List;

/**
 * Arrow/Enter navigation over a fixed, ordered list of {@link KeyboardFocusable} entries.
 *
 * <p>{@code scene2d.ui} gives none of this for free: no up/down/enter menu convention, no
 * wraparound, and its own keyboard focus ({@link Stage#setKeyboardFocus}) targets one actor for
 * text input, not a whole menu. This class owns the concept instead. Little Spaceship is a
 * keyboard-first shoot 'em up, so every menu screen wires one of these; the mouse keeps working
 * alongside it unchanged, since this only adds a listener rather than replacing scene2d's own
 * click handling.
 *
 * <p>Wired directly on the {@link Stage}, not on an individual actor: with no actor holding
 * scene2d's keyboard focus, {@code Stage#keyDown} dispatches straight to the root, which is where
 * {@link Stage#addListener} attaches.
 */
final class MenuNavigator {

    private final List<KeyboardFocusable> entries;
    private int focused;

    MenuNavigator(Stage stage, List<KeyboardFocusable> entries) {
        if (entries.isEmpty()) {
            throw new IllegalArgumentException("a menu screen needs at least one focusable entry");
        }
        this.entries = entries;
        this.focused = 0;
        entries.get(0).setFocused(true);

        stage.addListener(new InputListener() {
            @Override
            public boolean keyDown(InputEvent event, int keycode) {
                switch (keycode) {
                    case Input.Keys.UP:
                    case Input.Keys.W:
                        move(-1);
                        return true;
                    case Input.Keys.DOWN:
                    case Input.Keys.S:
                        move(1);
                        return true;
                    case Input.Keys.LEFT:
                    case Input.Keys.A:
                        entries.get(focused).adjust(-1);
                        return true;
                    case Input.Keys.RIGHT:
                    case Input.Keys.D:
                        entries.get(focused).adjust(1);
                        return true;
                    case Input.Keys.ENTER:
                    case Input.Keys.NUMPAD_ENTER:
                    case Input.Keys.SPACE:
                        entries.get(focused).activate();
                        return true;
                    default:
                        return false;
                }
            }
        });
    }

    private void move(int direction) {
        entries.get(focused).setFocused(false);
        focused = Math.floorMod(focused + direction, entries.size());
        entries.get(focused).setFocused(true);
    }
}
