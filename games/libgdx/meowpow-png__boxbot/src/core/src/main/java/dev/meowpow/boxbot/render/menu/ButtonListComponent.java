package dev.meowpow.boxbot.render.menu;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;
import dev.meowpow.boxbot.render.hud.HudPanelFrame;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.ObjectMap;

import java.util.Objects;

/**
 * A stack of selectable buttons, drawn top to bottom.
 */
@HotPath
public final class ButtonListComponent implements MenuComponent {

    private final MenuLabel[] buttons;
    private final BitmapFont font;
    private final float buttonHeight;
    private final float buttonGap;

    private final ObjectMap<MenuLabel, Boolean> buttonEnabled;
    private final HudPanelFrame buttonFrame;

    private final GlyphLayout buttonLayout = new GlyphLayout();
    private final Rectangle buttonBounds = new Rectangle();

    private @Nullable MenuLabel selected;

    /**
     * @param buttonHeight the height of one button, before scaling
     * @param buttonGap the vertical gap between buttons, before scaling
     *
     * @throws NullPointerException if {@code buttons} or {@code font} is null
     * @throws IllegalArgumentException if {@code scale} is not positive
     */
    public ButtonListComponent(
            MenuLabel[] buttons,
            BitmapFont font,
            int scale,
            float buttonHeight,
            float buttonGap
    ) {
        Objects.requireNonNull(buttons, "buttons must not be null");
        Objects.requireNonNull(font, "font must not be null");
        if (scale <= 0) {
            throw new IllegalArgumentException("scale must be positive: " + scale);
        }
        this.buttons = buttons;
        this.font = font;
        this.buttonHeight = buttonHeight * scale;
        this.buttonGap = buttonGap * scale;
        this.buttonEnabled = new ObjectMap<>(buttons.length);
        this.buttonFrame = new HudPanelFrame(
                RenderColors.MENU_PANEL_FILL_BUTTON,
                RenderColors.MENU_PANEL_BORDER_BUTTON,
                1f,
                1f,
                scale
        );
    }

    /**
     * Updates which button is drawn as selected.
     *
     * @param label the selected button, or null if nothing is selected
     */
    public void setSelected(@Nullable MenuLabel label) {
        this.selected = label;
    }

    /**
     * Returns whether the given button is currently available.
     */
    public boolean isEnabled(MenuLabel label) {
        return buttonEnabled.get(label, false);
    }

    /**
     * Updates whether the given button can be selected and activated.
     */
    public void setEnabled(MenuLabel label, boolean enabled) {
        buttonEnabled.put(label, enabled);
    }

    /**
     * Returns the button at the given point, if any.
     *
     * @return the button under the point, or null when it is outside every button
     */
    public @Nullable MenuLabel labelAt(float x, float y, float width, float pointX, float pointY) {
        for (int i = 0; i < buttons.length; i++) {
            buttonBounds.set(x, buttonY(y, i), width, buttonHeight);
            if (buttonBounds.contains(pointX, pointY)) {
                return buttons[i];
            }
        }
        return null;
    }

    @Override
    public float height() {
        return buttons.length * buttonHeight + (buttons.length - 1) * buttonGap;
    }

    @Override
    public void renderShapes(ShapeRenderer shapeRenderer, float x, float y, float width) {
        for (int i = 0; i < buttons.length; i++) {
            float buttonY = buttonY(y, i);
            buttonFrame.render(shapeRenderer, x, buttonY, width, buttonHeight);
            if (buttons[i] == selected) {
                drawSelectedBorder(shapeRenderer, x, buttonY, width);
            }
        }
    }

    @Override
    public void renderText(SpriteBatch batch, float x, float y, float width) {
        for (int i = 0; i < buttons.length; i++) {
            drawButtonLabel(batch, x, buttonY(y, i), width, buttons[i]);
        }
    }

    private void drawButtonLabel(SpriteBatch batch, float x, float y, float width, MenuLabel label) {
        if (!isEnabled(label)) {
            font.setColor(RenderColors.MENU_DISABLED_TEXT);
        }
        else if (label == selected) {
            font.setColor(RenderColors.ACCENT);
        }
        else {
            font.setColor(RenderColors.HUD_PANEL_BODY_FONT);
        }
        buttonLayout.setText(font, label.text());

        float labelX = x + (width - buttonLayout.width) / 2f;
        float labelY = y + (buttonHeight + buttonLayout.height) / 2f;

        font.draw(batch, buttonLayout, labelX, labelY);
    }

    private void drawSelectedBorder(ShapeRenderer shapeRenderer, float x, float y, float width) {
        float thickness = 2f;
        shapeRenderer.setColor(RenderColors.ACCENT);
        shapeRenderer.rect(x, y + buttonHeight - thickness, width, thickness);
        shapeRenderer.rect(x, y, width, thickness);
        shapeRenderer.rect(x, y, thickness, buttonHeight);
        shapeRenderer.rect(x + width - thickness, y, thickness, buttonHeight);
    }

    private float buttonY(float y, int index) {
        float top = y + height();
        float distanceFromTop = index * (buttonHeight + buttonGap);
        return top - distanceFromTop - buttonHeight;
    }
}
