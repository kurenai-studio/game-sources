package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import dev.luchoc.littlespaceship.game.adapter.content.JsonContentSource;
import dev.luchoc.littlespaceship.game.ui.Palette;
import java.util.ArrayList;
import java.util.List;

/**
 * Ship selection/building, per {@code docs/planning/02-mvp-functional-spec.md}: one selectable
 * ship, its characteristics, and a screen conceptually ready for more without offering unlocking,
 * purchase or deep customisation — none of which the MVP has.
 *
 * <p>The empty second slot from {@code docs/design/mockups/screens.html} is not drawn here: the
 * spec calls it optional, and the design note for it — "it says the system grows without promising
 * anything" — is exactly the kind of promise this screen has no data to back yet. It can be added
 * with no layout change once a second ship exists to slot in.
 */
public final class ShipSelectScreen extends BaseUiScreen {

    public ShipSelectScreen(LittleSpaceshipGame game) {
        super(game, "SELECT SHIP");
        content.top().left();

        Label name = new Label("PROTOTYPE X-1", skin, "hud-label");
        Label description = new Label("SUSTAINED SHOT, BOMB, SLOW MODE", skin, "body");
        content.add(name).left().padBottom(6f).row();
        content.add(description).left().padBottom(16f).row();

        // The header labels used to sit alone with no numbers beside them — not a legibility issue,
        // the values simply were not read from anywhere. BalanceValues is what content.balance()
        // already exposes about the one MVP ship; a second content source instance costs nothing at
        // load time and keeps this screen free of a Simulation it has no other reason to start.
        BalanceValues balance =
            new JsonContentSource(Gdx.files.internal("data"), game.levelId()).balance();
        Table stats = new Table();
        addStatBar(stats, "SPEED", speedSegments(balance.playerSpeed()));
        addStatBar(stats, "FIRE", fireRateSegments(balance.weaponFireCooldown()));
        addStatBar(stats, "BOMBS", scaleSegments(balance.initialBombs(), balance.maxBombs()));
        addStatBar(stats, "LIVES", scaleSegments(balance.initialLives(), balance.maxLives()));
        content.add(stats).left().padBottom(24f).row();

        List<KeyboardFocusable> focusables = new ArrayList<>();
        MenuEntries.add(content, game, skin, "LAUNCH", () -> game.setScreen(new PlayScreen(game)), focusables);
        MenuEntries.add(content, game, skin, "BACK", () -> game.setScreen(new MenuScreen(game)), focusables);
        new MenuNavigator(stage, focusables);
    }

    private static final int STAT_SEGMENTS = 5;

    /**
     * One header/bar column, per {@code docs/design/mockups/src/05-screens.js}'s {@code statBar} —
     * five segments, filled in {@code C1} with a {@code C2} top row, empty outlined in {@code N3},
     * the exact fill style {@code HudRenderer}'s own POWER segments use. Raw engine units such as
     * {@code 140} px/s do not mean anything to a player choosing between ships; a bar does.
     */
    private void addStatBar(Table table, String header, int filledSegments) {
        Table column = new Table();
        column.add(new Label(header, skin, "hud-label")).left().padBottom(4f).row();
        Table bar = new Table();
        for (int i = 0; i < STAT_SEGMENTS; i++) {
            boolean filled = i < filledSegments;
            Image segment = new Image(skin.newDrawable("white", filled ? Palette.C1 : Palette.N2));
            bar.add(segment).width(8f).height(7f).padRight(2f);
        }
        column.add(bar).left();
        table.add(column).left().padRight(24f);
    }

    /**
     * {@code value} scaled from {@code [0, cap]} into {@code [0, STAT_SEGMENTS]} segments — a
     * presentation-only scale for a bar's fill, not a game rule; {@code BOMBS 2/3} and
     * {@code LIVES 3/5} still come straight from {@link BalanceValues}.
     */
    private static int scaleSegments(int value, int cap) {
        if (cap <= 0) {
            return 0;
        }
        return Math.round(STAT_SEGMENTS * Math.min(1f, (float) value / cap));
    }

    /** Plausible speed range for the one MVP ship, purely to pick a bar length — not a balance cap. */
    private static int speedSegments(float speed) {
        return Math.round(STAT_SEGMENTS * clamp01((speed - 80f) / (200f - 80f)));
    }

    /** Lower cooldown reads as a fuller bar: faster fire is the better stat. */
    private static int fireRateSegments(float cooldown) {
        return Math.round(STAT_SEGMENTS * clamp01((0.30f - cooldown) / (0.30f - 0.05f)));
    }

    private static float clamp01(float value) {
        return Math.max(0f, Math.min(1f, value));
    }
}
