package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.scenes.scene2d.ui.Label;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;

/**
 * The end-of-level bonus, per {@code docs/planning/10-mvp-initial-values.md}'s per-life and
 * per-bomb completion bonus. Retrying is optional per
 * {@code docs/planning/02-mvp-functional-spec.md}, so the only exit is back to the menu.
 *
 * <p>{@link PlayScreen} opens this screen when {@code WorldView.outcome()} reports {@code
 * LevelOutcome.COMPLETED} — the wave timeline ran dry with no enemy left and at least one life
 * held. That is deliberately not called {@code VICTORY} on the {@code core} side: nothing in the
 * MVP shipped so far can honestly claim the boss fight the spec's flow describes, since the boss is
 * phase 07's. This screen still reads "VICTORY", per the flow's own copy in {@code
 * docs/design/mockups/screens.html} — the caveat is about what the signal proves, not about what
 * the player is told.
 */
public final class VictoryScreen extends BaseUiScreen {

    public VictoryScreen(LittleSpaceshipGame game, int score, int livesBonus, int bombsBonus) {
        super(game, "VICTORY");
        content.top().left();

        Label subtitle = new Label(
            "THE ATTACK ZONE IS CLEAR. THE INVASION IS NOT.", skin, "body");
        content.add(subtitle).left().padBottom(20f).row();

        addRow("SCORE", score);
        addRow("LIVES BONUS", livesBonus);
        addRow("BOMBS BONUS", bombsBonus);

        Label total = new Label("TOTAL   " + zeroPadded(score + livesBonus + bombsBonus), skin, "title");
        content.add(total).left().padTop(12f).padBottom(20f).row();

        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(content, game, skin, "CONTINUE", () -> game.setScreen(new MenuScreen(game)), focusables);
        new MenuNavigator(stage, focusables);
    }

    private void addRow(String label, int value) {
        Label row = new Label(label + "   " + zeroPadded(value), skin, "body");
        content.add(row).left().padBottom(6f).row();
    }

    private static String zeroPadded(int value) {
        String raw = Integer.toString(Math.max(0, value));
        StringBuilder sb = new StringBuilder();
        for (int i = raw.length(); i < 7; i++) {
            sb.append('0');
        }
        return sb.append(raw).toString();
    }
}
