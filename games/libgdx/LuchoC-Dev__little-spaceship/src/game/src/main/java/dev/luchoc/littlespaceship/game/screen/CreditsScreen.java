package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Screen;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

/**
 * The one entry {@code docs/design/mockups/src/05-screens.js}'s Options screen lists that
 * {@link OptionsScreen} did not have anywhere to send: engine and library attribution, listed as
 * plain text with a single BACK, the same shape every other screen in this flow uses for a list with
 * nothing to configure.
 *
 * <p>{@code previousFactory} takes a {@link Supplier}, not a {@link Screen} instance, for the same
 * reason {@link OptionsScreen}'s own BACK does — see its class javadoc.
 */
public final class CreditsScreen extends BaseUiScreen {

    public CreditsScreen(LittleSpaceshipGame game, Supplier<Screen> previousFactory) {
        super(game, "CREDITS AND LICENCES");
        content.top().left();

        addLine("libGDX — Apache License 2.0");
        addLine("LWJGL3 — BSD-3-Clause");
        addLine("GDX-TeaVM — Apache License 2.0");
        addLine("No third-party art or audio is used in this build.");

        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(content, game, skin, "BACK", () -> game.setScreen(previousFactory.get()), focusables);
        new MenuNavigator(stage, focusables);
    }

    private void addLine(String text) {
        content.add(new Label(text, skin, "body")).left().padBottom(8f).row();
    }
}
