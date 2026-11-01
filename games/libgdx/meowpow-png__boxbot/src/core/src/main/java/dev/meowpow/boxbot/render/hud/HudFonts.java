package dev.meowpow.boxbot.render.hud;

import com.badlogic.gdx.graphics.g2d.BitmapFont;

import java.util.Objects;

/**
 * The header and body fonts used to draw HUD panel content.
 *
 * @param header the font used for panel headers
 * @param body the font used for panel labels and values
 */
public record HudFonts(BitmapFont header, BitmapFont body) {

    public HudFonts {
        Objects.requireNonNull(header, "header must not be null");
        Objects.requireNonNull(body, "body must not be null");
    }
}
