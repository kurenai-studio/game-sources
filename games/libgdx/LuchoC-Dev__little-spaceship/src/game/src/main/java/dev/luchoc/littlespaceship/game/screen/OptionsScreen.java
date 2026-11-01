package dev.luchoc.littlespaceship.game.screen;

import com.badlogic.gdx.Screen;
import com.badlogic.gdx.scenes.scene2d.ui.CheckBox;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Slider;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import dev.luchoc.littlespaceship.game.GameSettings;
import dev.luchoc.littlespaceship.game.LittleSpaceshipGame;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

/**
 * Master, music and effects volume, and the mouse-control switch — exactly
 * {@code docs/planning/02-mvp-functional-spec.md}'s Options list. No key remapping and no
 * difficulty selector: both are explicit MVP exclusions, not omissions.
 *
 * <p><b>BACK takes a {@link Supplier}, not a {@link Screen} instance.</b> {@link
 * LittleSpaceshipGame#setScreen} disposes the outgoing screen the moment a new one is set — see its
 * own javadoc — so a {@code Screen previous} captured here would already be disposed by the time
 * BACK tries to show it again whenever this screen was reached by replacing that instance (menu ->
 * Options is exactly that path: {@code MenuScreen} passes {@code this}, and setting Options disposes
 * it). A factory sidesteps the contradiction instead of special-casing one call site: it is never
 * evaluated until BACK is actually pressed, so it always builds a live screen, and it costs nothing
 * while unused since menus are cheap to construct.
 */
public final class OptionsScreen extends BaseUiScreen {

    public OptionsScreen(LittleSpaceshipGame game, Supplier<Screen> previousFactory) {
        super(game, "OPTIONS");
        GameSettings settings = game.settings();
        content.top().left();
        List<KeyboardFocusable> focusables = new ArrayList<>();

        addSlider(content, "MASTER VOLUME", settings.masterVolume(),
            value -> { settings.masterVolume(value); game.audio().refreshVolume(); }, focusables);
        addSlider(content, "MUSIC VOLUME", settings.musicVolume(),
            value -> { settings.musicVolume(value); game.audio().refreshVolume(); }, focusables);
        addSlider(content, "EFFECTS VOLUME", settings.effectsVolume(), settings::effectsVolume, focusables);

        CheckBox mouseToggle = new CheckBox(" MOUSE CONTROL", skin);
        mouseToggle.setChecked(settings.mouseEnabled());
        mouseToggle.addListener(event -> {
            settings.mouseEnabled(mouseToggle.isChecked());
            return false;
        });
        Table mouseRow = new Table();
        mouseRow.add(mouseToggle).left();
        content.add(mouseRow).left().padTop(8f).padBottom(16f).row();
        focusables.add(rowFocusable(mouseRow, () -> mouseToggle.setChecked(!mouseToggle.isChecked())));

        MenuEntries.add(content, game, skin, "CREDITS AND LICENCES",
            () -> game.setScreen(new CreditsScreen(game, () -> new OptionsScreen(game, previousFactory))),
            focusables);
        MenuEntries.add(content, game, skin, "BACK", () -> game.setScreen(previousFactory.get()), focusables);
        new MenuNavigator(stage, focusables);
    }

    private void addSlider(Table table, String labelText, float initial,
            java.util.function.Consumer<Float> onChange, List<KeyboardFocusable> focusables) {
        Table row = new Table();
        Label label = new Label(labelText, skin, "hud-label");
        Slider slider = new Slider(0f, 1f, 0.01f, false, skin);
        slider.setValue(initial);
        Label percent = new Label(Integer.toString(Math.round(initial * 100)), skin, "body");
        slider.addListener(event -> {
            onChange.accept(slider.getValue());
            percent.setText(Integer.toString(Math.round(slider.getValue() * 100)));
            return false;
        });
        row.add(label).width(150f).left();
        row.add(slider).width(120f).padLeft(16f);
        row.add(percent).width(40f).padLeft(16f);
        table.add(row).left().padBottom(12f).row();

        focusables.add(rowFocusable(row, () -> {
            // Enter/Space on a slider bumps it one step, the same amount arrow keys already move it
            // through KeyboardFocusable.adjust below; a slider has a value to nudge, not a single
            // action to fire, so activate() and adjust() end up doing the same thing here.
            slider.setValue(Math.min(1f, slider.getValue() + 0.05f));
        }, direction -> slider.setValue(
            Math.max(0f, Math.min(1f, slider.getValue() + direction * 0.05f)))));
    }

    /**
     * Wraps a row (a slider row or the mouse-toggle row) as a {@link KeyboardFocusable} whose focus
     * indicator is a border, not a font colour change — neither a {@link Slider} nor a {@link
     * CheckBox} has a style field {@code TextButton.checkedFontColor} does, so the button-style
     * highlight {@link MenuEntries} uses does not apply here. The border is {@code n1-panel}, the
     * same drawable {@link BaseUiScreen}'s panels already use, so a focused row reads as "this is a
     * panel now" rather than introducing a third visual language for focus in the same screen.
     */
    private KeyboardFocusable rowFocusable(Table row, Runnable activate) {
        return rowFocusable(row, activate, direction -> {
        });
    }

    private KeyboardFocusable rowFocusable(
            Table row, Runnable activate, java.util.function.IntConsumer adjust) {
        Skin skin = this.skin;
        return new KeyboardFocusable() {
            @Override
            public void setFocused(boolean focused) {
                row.setBackground(focused ? skin.getDrawable("n1-panel") : null);
            }

            @Override
            public void activate() {
                activate.run();
            }

            @Override
            public void adjust(int direction) {
                adjust.accept(direction);
            }
        };
    }
}
