package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.scenes.scene2d.ui.Label;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;

/**
 * Retry or menu, nothing else — {@code docs/planning/02-mvp-functional-spec.md}'s Defeat screen.
 * There are no checkpoints in the MVP, so there is nothing else to offer.
 *
 * <p>{@link PlayScreen} opens this screen when {@code WorldView.outcome()} reports {@code
 * LevelOutcome.DEFEATED} — {@code Player.lives} reached zero, exactly what
 * {@code 02-mvp-functional-spec.md} names for a loss, with no caveat needed the way {@link
 * VictoryScreen}'s outcome has one.
 */
public final class DefeatScreen extends BaseUiScreen {

    public DefeatScreen(LittleSpaceshipGame game, int score) {
        super(game, "GAME OVER");
        content.top().left();

        Label subtitle = new Label("THE SHIP WAS LOST OVER THE CITY.", skin, "body");
        content.add(subtitle).left().padBottom(20f).row();

        Label scoreLabel = new Label("SCORE   " + zeroPadded(score), skin, "title");
        content.add(scoreLabel).left().padBottom(24f).row();

        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(content, game, skin, "RETRY", () -> game.setScreen(new ShipSelectScreen(game)), focusables);
        MenuEntries.add(content, game, skin, "QUIT TO MENU", () -> game.setScreen(new MenuScreen(game)), focusables);
        new MenuNavigator(stage, focusables);
    }

    /**
     * Zero-padded to 7 digits, the same width {@link VictoryScreen} pads its own score to per
     * {@code docs/design/mockups/src/05-screens.js} — both end screens show the same field, so
     * neither can disagree with the other about its width.
     */
    private static String zeroPadded(int value) {
        String raw = Integer.toString(Math.max(0, value));
        StringBuilder sb = new StringBuilder();
        for (int i = raw.length(); i < 7; i++) {
            sb.append('0');
        }
        return sb.append(raw).toString();
    }
}
