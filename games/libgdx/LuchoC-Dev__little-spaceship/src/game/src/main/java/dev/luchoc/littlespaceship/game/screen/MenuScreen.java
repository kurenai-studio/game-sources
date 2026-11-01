package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Application.ApplicationType;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;

/**
 * The main menu: Play, Options, Quit — {@code docs/planning/02-mvp-functional-spec.md}'s exact
 * list, with no locked mode and no "coming soon" entry, per the spec's own exclusion and per
 * {@code docs/design/mockups/screens.html}'s note that drawing either would promise something the
 * build does not have.
 */
public final class MenuScreen extends BaseUiScreen {

    public MenuScreen(LittleSpaceshipGame game) {
        super(game, "LITTLE SPACESHIP");
        // Entering the main menu ends whatever scenario TESTS started, so PLAY always starts the
        // campaign level, not the last scenario opened. A no-op outside the -Ptests flavour, since
        // the override is already always null there — see issue #305.
        game.clearLevelIdOverride();
        content.top().left();

        Label subtitle = new Label(
            "AN EXPERIMENTAL SHIP AGAINST THE FIRST WAVE", skin, "body");
        content.add(subtitle).left().padBottom(20f).row();

        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(content, game, skin, "PLAY", () -> game.setScreen(new ShipSelectScreen(game)), focusables);
        MenuEntries.add(content, game, skin, "OPTIONS",
            () -> game.setScreen(new OptionsScreen(game, () -> new MenuScreen(game))), focusables);
        // A no-op in every build that reaches a player; adds a TESTS entry only in the -Ptests
        // flavour, per TestMode's own javadoc and game/build.gradle.kts.
        TestMode.addMenuEntry(content, game, skin, focusables);
        // On the web target, Gdx.app.exit() does nothing: a script may not close a tab it did not
        // itself open. QUIT keeps its slot but leads to a farewell screen there instead of exiting;
        // see FarewellScreen's class javadoc and issue #40.
        Runnable quit = Gdx.app.getType() == ApplicationType.WebGL
            ? () -> game.setScreen(new FarewellScreen(game))
            : Gdx.app::exit;
        MenuEntries.add(content, game, skin, "QUIT", quit, focusables);
        new MenuNavigator(stage, focusables);

        Table footerRow = new Table();
        footerRow.add(new Label("MVP BUILD", skin, "body")).left();
        content.add(footerRow).left().expandY().bottom().padBottom(0f).row();
    }
}
