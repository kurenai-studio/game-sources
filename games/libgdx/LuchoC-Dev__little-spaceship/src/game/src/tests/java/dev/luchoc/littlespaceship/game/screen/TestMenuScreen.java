package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.scenes.scene2d.ui.ScrollPane;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;

/**
 * The TESTS submenu: one entry per {@link TestScenarios.Scenario}, each starting the game directly
 * in that scenario. Present only in the {@code -Ptests} build flavour — see {@code TestMode} and
 * {@code game/build.gradle.kts}. That flavour's {@code LittleSpaceshipGame#create()} opens this
 * screen directly at startup (issue #250: the build exists for exactly one purpose, so the main
 * menu is a step with no reason to be there); {@link MenuScreen}'s TESTS entry reaches it again
 * from anywhere else in the flow.
 *
 * <p>BACK leads to {@link MenuScreen}, not back to whatever screen preceded this one — deliberately:
 * this screen has no "preceding screen" to return to when it is also the one the run started on,
 * and {@link MenuScreen} still carries the TESTS entry in this flavour, so BACK never strands the
 * player. The main menu is skipped only at startup, not on every path back to it.
 *
 * <p>Goes straight to {@link PlayScreen}, skipping {@link ShipSelectScreen}: a scenario's starting
 * state — weapon level, lives, bombs — is the level file's own decision per
 * {@code docs/plan/11h-test-mode/plan.md}, not a choice this screen offers.
 *
 * <p><b>Scrolls (issue #276).</b> Nine entries — eight scenarios plus BACK — no longer fit inside
 * {@link BaseUiScreen}'s 480x270 frame, and {@code content} is a plain, unclipped {@code Table}, so
 * anything past the fold was simply unreachable. The fix lives entirely here, not in
 * {@code BaseUiScreen}: the entries go into their own {@code Table} wrapped in a
 * {@link ScrollPane}, which is added as {@code content}'s single child instead of holding the
 * buttons directly. {@code BaseUiScreen} itself, and every shipped screen built on it, is
 * unchanged — this screen is the one place in the whole flow where an entry list is expected to
 * keep growing (one line per test scenario, per {@code TestScenarios}), so it is also the one
 * place that earns the extra machinery. Whether {@code BaseUiScreen} should stop silently
 * dropping content that overflows it, for every screen rather than just this one, is a real
 * question — see the status fragment for #276; it is deliberately not answered here.
 */
final class TestMenuScreen extends BaseUiScreen {

    TestMenuScreen(LittleSpaceshipGame game) {
        super(game, "TESTS");

        Table entries = new Table();
        entries.top().left();

        ScrollPane scrollPane = new ScrollPane(entries);
        // Vertical list, so horizontal scrolling has nothing to do; disabling it also stops the
        // pane fighting MenuNavigator's own left/right, which this screen does not use anyway.
        scrollPane.setScrollingDisabled(true, false);
        scrollPane.setOverscroll(false, false);
        content.top().left();
        content.add(scrollPane).expand().fill();

        List<KeyboardFocusable> focusables = new ArrayList<>();
        for (TestScenarios.Scenario scenario : TestScenarios.all()) {
            addScrollingEntry(entries, scrollPane, game, scenario.label(), () -> {
                game.overrideLevelId(scenario.levelId());
                game.setScreen(new PlayScreen(game));
            }, focusables);
        }
        addScrollingEntry(entries, scrollPane, game, "BACK",
            () -> game.setScreen(new MenuScreen(game)), focusables);

        // MenuNavigator focuses the first entry immediately, in its own constructor below, and
        // that first setFocused(true) call scrolls to it through addScrollingEntry's wrapper — but
        // scrolling needs the button's real position, which does not exist before a layout pass
        // runs. validate() gets that layout pass done first; without it every button still reports
        // (0, 0), and scrolling to "the rectangle at (0, 0)" lands near the *last* row rather than
        // doing nothing, because y grows upward and the bottom-most row is the one actually near
        // y = 0 — confirmed on a real launch, the menu opened scrolled past WAVE 4 until this line
        // was added. setScrollY(0) afterwards is the belt to that brace: it pins the very first
        // open of this screen to the top regardless of any rounding in scrollTo's own "minimum
        // distance to make it visible" logic, which is what still left WAVE 4 one row above the
        // fold with validate() alone.
        content.validate();
        new MenuNavigator(stage, focusables);
        scrollPane.setScrollY(0f);
    }

    /**
     * Wraps {@link MenuEntries#add} so that gaining keyboard focus also scrolls the entry into
     * view. Plain {@link MenuEntries}/{@link MenuNavigator} have no notion of a scrollable
     * container — no other screen has ever needed one — so that behaviour is added here instead of
     * touching either shared class for a need this screen alone has.
     *
     * <p><b>The first entry cannot rely on {@code scrollTo} (issue #293).</b> {@code ScrollPane}'s
     * own "minimal distance to make the rectangle visible" clamp lands exactly on the boundary
     * scroll offset where the target row has zero pixels of overlap with the viewport, not one —
     * confirmed by reproducing the exact down-then-up navigation outside this codebase, against the
     * real {@code ScrollPane} class, with the same trailing-gap row geometry {@link
     * MenuEntries#add} builds ({@code padBottom} trails every row, including the first). Every
     * other row still has enough slack on at least one side for the clamp to land inside the
     * visible range instead of on its edge, so only the first row needs the explicit override:
     * {@link ScrollPane#setScrollY} to the pane's own top, mirroring the guard the constructor
     * already applies on first open, rather than trusting {@code scrollTo}'s minimal move.
     */
    private void addScrollingEntry(Table entries, ScrollPane scrollPane,
            LittleSpaceshipGame game, String label, Runnable action,
            List<KeyboardFocusable> focusables) {
        boolean isFirstEntry = focusables.isEmpty();
        TextButton button = MenuEntries.add(entries, game, skin, label, action, focusables);
        KeyboardFocusable inner = focusables.remove(focusables.size() - 1);
        focusables.add(new KeyboardFocusable() {
            @Override
            public void setFocused(boolean focused) {
                inner.setFocused(focused);
                if (focused) {
                    if (isFirstEntry) {
                        scrollPane.setScrollY(0f);
                    } else {
                        scrollPane.scrollTo(button.getX(), button.getY(),
                            button.getWidth(), button.getHeight());
                    }
                }
            }

            @Override
            public void activate() {
                inner.activate();
            }

            @Override
            public void adjust(int direction) {
                inner.adjust(direction);
            }
        });
    }
}
