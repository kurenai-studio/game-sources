package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;
import dev.meowpow.boxbot.render.effect.ScreenTint;
import dev.meowpow.boxbot.render.hud.HudPanelFrame;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.graphics.Color;

import java.util.Objects;

/**
 * Draws a centered, in-game menu screen.
 */
@HotPath
public final class MenuRenderer {

    private final MenuCanvas canvas;
    private final MenuLayout layout;

    private final ScreenTint dimOverlay = new ScreenTint();
    private final HudPanelFrame panelFrame;

    /**
     * @throws NullPointerException if {@code canvas}, {@code layout}, or {@code dimColor} is null
     * @throws IllegalArgumentException if {@code scale} is not positive
     */
    public MenuRenderer(MenuCanvas canvas, MenuLayout layout, int scale, Color dimColor) {
        Objects.requireNonNull(canvas, "canvas must not be null");
        Objects.requireNonNull(layout, "layout must not be null");
        Objects.requireNonNull(dimColor, "dimColor must not be null");
        if (scale <= 0) {
            throw new IllegalArgumentException("scale must be positive: " + scale);
        }
        this.canvas = canvas;
        this.layout = layout;

        dimOverlay.setColor(dimColor);
        panelFrame = new HudPanelFrame(
                RenderColors.MENU_PANEL_FILL,
                RenderColors.MENU_PANEL_BORDER_OUTER,
                2f,
                1f,
                scale
        );
    }

    /**
     * Draws the dimmed overlay and every stacked component.
     *
     * @param selectedLabel the enabled item selected by keyboard
     * or mouse input, or null if nothing is currently selected
     */
    public void render(@Nullable MenuLabel selectedLabel) {
        if (layout.buttons() != null) {
            layout.buttons().setSelected(selectedLabel);
        }
        float panelX = panelX();
        float panelY = panelY();
        float contentX = panelX + layout.padding();
        float contentWidth = layout.contentWidth();
        var components = layout.components();

        var shapeRenderer = canvas.shapeRenderer();
        canvas.beginShapes();
        dimOverlay.render(shapeRenderer, canvas.screenWidth(), canvas.screenHeight());
        panelFrame.render(shapeRenderer, panelX, panelY, layout.panelWidth(), layout.panelHeight());
        for (int i = 0; i < components.length; i++) {
            var renderY = panelY + layout.componentY(i);
            components[i].renderShapes(shapeRenderer, contentX, renderY, contentWidth);
        }
        canvas.endShapes();

        var batch = canvas.batch();
        canvas.beginBatch();
        for (int i = 0; i < components.length; i++) {
            var renderY = panelY + layout.componentY(i);
            components[i].renderText(batch, contentX, renderY, contentWidth);
        }
        canvas.endBatch();
    }

    /**
     * Returns the button at the given screen-space point, if any.
     *
     * @param screenX the horizontal screen coordinate, in pixels
     * @param screenY the vertical screen coordinate, in pixels
     *
     * @return the item under the point, or null when it is outside every button
     */
    public @Nullable MenuLabel labelAt(int screenX, int screenY) {
        if (layout.buttons() == null) {
            return null;
        }
        return layout.buttons().labelAt(
                panelX() + layout.padding(),
                panelY() + layout.buttonsY(),
                layout.contentWidth(),
                screenX,
                canvas.screenHeight() - screenY
        );
    }

    /**
     * Returns whether the given button is currently
     * available or false if the button does not exist.
     */
    public boolean isEnabled(MenuLabel label) {
        if (layout.buttons() == null) {
            return false;
        }
        return layout.buttons().isEnabled(label);
    }

    /**
     * Updates whether the given button
     * can be selected and activated.
     * <p>
     * No-op if the button does not exist.
     */
    public void setEnabled(MenuLabel label, boolean enabled) {
        if (layout.buttons() != null) {
            layout.buttons().setEnabled(label, enabled);
        }
    }

    private float panelX() {
        return (canvas.screenWidth() - layout.panelWidth()) / 2f;
    }

    private float panelY() {
        return (canvas.screenHeight() - layout.panelHeight()) / 2f + layout.verticalOffset();
    }
}
