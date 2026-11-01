package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.ui.Cell;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import dev.luchoc.littlespaceship.game.adapter.audio.Sfx;
import java.util.List;

/**
 * A vertical stack of {@code font-mini} entries, per {@code docs/design/04-hud-layout.md}'s "16 px
 * between entries".
 *
 * <p>Selection state has two independent sources now: libGDX's own hover/press styling for the
 * mouse ({@code overFontColor}/{@code downFontColor}, {@code W4} per the design doc), and keyboard
 * focus for {@link MenuNavigator}, which this class also registers each button under —
 * {@code button.setChecked(true)} drives {@code checkedFontColor}, the same {@code W4}, and a
 * "> " prefix on the label so the focused entry differs in shape as well as colour, per
 * {@code 05-legibility-rules.md} R4. Both mechanisms coexist without conflict: a mouse hover and a
 * keyboard focus simply agree on which entry looks selected when they happen to be the same one.
 *
 * <p><b>This is also where every screen's audio gets unlocked.</b> {@link
 * dev.luchoc.littlespaceship.game.adapter.audio.AudioSystem#unlock()} is called here, once per
 * activation but idempotent, because a click or an Enter key press reaching this method is by
 * construction a real user gesture — the exact thing a browser waits for before it allows audio to
 * play at all. Every menu entry in the game goes through {@link #add}, so this is the one place
 * that needs to know the rule exists.
 */
final class MenuEntries {

    /** Vertical breathing room inside the plate, above and below the 10 px line. */
    private static final float PAD_V = 3f;

    /** Horizontal padding inside the plate, the same whether the entry is focused or not. */
    private static final float PAD_H = 6f;

    /**
     * How much wider the focused entry's plate is drawn, in pixels.
     *
     * <p>This is the "the selection grows" affordance, and it has to be driven from the cell's width
     * rather than from the button's padding. The plate carries {@code 04-hud-layout.md}'s 60 px
     * minimum, and a short entry like {@code PLAY} sits under that minimum even with padding added —
     * so extra padding is simply absorbed and nothing moves. Widening the cell is measured after that
     * minimum applies, so it shows on every entry rather than only on the long ones.
     *
     * <p>The placeholder font used to give this away for free: every entry was then sized to its own
     * text, so swapping the two-space lead for {@code "> "} made the focused plate visibly wider.
     * Real {@code font-mini} has a fixed 6 px advance, so that swap now costs exactly zero pixels and
     * the movement disappeared with it. Whole pixels, never a scale factor — scaling the plate would
     * put its 1 px frame on half pixels and break the project's integer-scaling invariant.
     */
    private static final float FOCUS_GROWTH = 6f;

    private MenuEntries() {
    }

    /**
     * Adds a button and registers it with {@code focusables} so a {@link MenuNavigator} built from
     * that list afterwards can reach it with the keyboard.
     */
    static TextButton add(Table table, LittleSpaceshipGame game, Skin skin, String label,
            Runnable action, List<KeyboardFocusable> focusables) {
        TextButton button = new TextButton("  " + label, skin);
        // The 2-character lead ("  " / "> ") is the marker's own 12 px gutter from
        // 04-hud-layout.md — two glyphs at font-mini's fixed 6 px advance — not padding.
        // Centred, not left-aligned: the plate has a 60 px minimum, so a short label like PLAY
        // (24 px of glyphs plus the gutter) leaves slack, and left alignment dumps all of it on
        // the right edge. Centring splits it, which is what stops a short entry reading as
        // lopsided. The marker keeps its 12 px relationship to the text either way, since it
        // travels inside the same string.
        button.getLabel().setAlignment(com.badlogic.gdx.utils.Align.center);
        button.pad(PAD_V, PAD_H, PAD_V, PAD_H);
        button.addListener(new ClickListener() {
            @Override
            public void clicked(InputEvent event, float x, float y) {
                activate(game, action);
            }
        });
        // Measured once, before any focus marker is in the text, so the width does not depend on
        // which entry happens to be selected when the screen is built.
        float idleWidth = button.getPrefWidth();
        Cell<TextButton> cell = table.add(button).left().width(idleWidth).padBottom(16f);
        table.row();

        focusables.add(new KeyboardFocusable() {
            @Override
            public void setFocused(boolean focused) {
                button.setChecked(focused);
                button.setText((focused ? "> " : "  ") + label);
                cell.width(focused ? idleWidth + FOCUS_GROWTH : idleWidth);
                // The cell's width changed, so the table has to be measured again; without this the
                // new width is stored and never drawn.
                button.invalidateHierarchy();
            }

            @Override
            public void activate() {
                MenuEntries.activate(game, action);
            }
        });
        return button;
    }

    private static void activate(LittleSpaceshipGame game, Runnable action) {
        game.audio().unlock();
        game.audio().playSfx(Sfx.UI_SELECT);
        action.run();
    }
}
