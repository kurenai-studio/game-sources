package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;

import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

import java.util.Objects;

/**
 * A panel content row pairing a fixed,
 * left-aligned label with a right-aligned value.
 */
@HotPath
public final class HudLabelValue {

    private final HudText label, value;

    /**
     * Creates a label/value pair drawn with the given font.
     *
     * @param font the font to draw both label and value with
     * @param labelText the label's fixed text
     *
     * @throws NullPointerException if either argument is null
     */
    HudLabelValue(BitmapFont font, String labelText) {
        Objects.requireNonNull(font, "font must not be null");
        Objects.requireNonNull(labelText, "labelText must not be null");

        this.label = new HudText(font, HudText.Alignment.LEFT, RenderColors.HUD_PANEL_BODY_FONT);
        this.label.setText(labelText);
        this.value = new HudText(font, HudText.Alignment.RIGHT, RenderColors.HUD_PANEL_BODY_FONT);
    }

    /**
     * Returns this pair's value text.
     */
    HudText value() {
        return value;
    }

    /**
     * Draws this pair's label and value at the given row.
     *
     * @param batch the batch to draw into
     * @param row the content row grid to draw within
     * @param rowIndex the row's index, counting top to bottom from zero
     */
    void render(SpriteBatch batch, HudPanelBase.ContentRow row, int rowIndex) {
        row.render(batch, rowIndex, label, value);
    }
}
