package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.scenes.scene2d.ui.Label;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;

/**
 * What QUIT means on the web target, where {@code Gdx.app.exit()} closes nothing: a browser tab may
 * not be closed by the script running inside it, so the entry keeps its slot in the menu but leads
 * here instead of to {@code Gdx.app::exit} — a farewell rather than an exit, with the one way back
 * every other screen in this flow gives a dead end, per {@link MenuScreen}. Structured like {@link
 * CreditsScreen}: plain text, a single BACK, {@link MenuNavigator} for the keyboard.
 *
 * <p>There is no run in progress when QUIT is reached — it lives on the main menu, not the pause
 * panel — so this is a farewell, not a results screen. It does not show a score, and none is
 * persisted for it to show: see {@code GameSettings}, which persists only volume and the mouse
 * toggle.
 */
public final class FarewellScreen extends BaseUiScreen {

    public FarewellScreen(LittleSpaceshipGame game) {
        super(game, "THANKS FOR PLAYING");
        content.top().left();

        addLine("That's the whole MVP for now.");
        addLine("More waves and ships are on the way.");

        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(content, game, skin, "BACK TO MENU", () -> game.setScreen(new MenuScreen(game)),
            focusables);
        new MenuNavigator(stage, focusables);
    }

    private void addLine(String text) {
        content.add(new Label(text, skin, "body")).left().padBottom(8f).row();
    }
}
