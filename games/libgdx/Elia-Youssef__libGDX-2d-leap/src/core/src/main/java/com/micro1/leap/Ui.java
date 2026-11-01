package com.micro1.leap;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * Small text helpers shared by the screens. The built-in BitmapFont is scaled
 * per call so capital letters render at an approximate pixel height, and text is
 * centered around a point. Keeping these here avoids duplicating the GlyphLayout
 * math in TitleScreen and GameScreen.
 */
public final class Ui {

    private static final GlyphLayout LAYOUT = new GlyphLayout();

    private Ui() {}

    /** Scale the font so capital letters are about targetPx tall. */
    public static void setHeight(BitmapFont font, float targetPx) {
        font.getData().setScale(1f);                 // reset to native metrics
        float cap = font.getCapHeight();             // native cap height in px
        font.getData().setScale(targetPx / cap);
    }

    /**
     * Draw text centered horizontally on centerX with its visual middle at
     * centerY, scaled to about targetPx tall, in the given color.
     */
    public static void drawCentered(SpriteBatch batch, BitmapFont font, String text,
                                    float centerX, float centerY, float targetPx, Color color) {
        setHeight(font, targetPx);
        font.setColor(color);
        LAYOUT.setText(font, text);
        float x = centerX - LAYOUT.width / 2f;
        float y = centerY + LAYOUT.height / 2f;      // font.draw y is the top of the text
        font.draw(batch, LAYOUT, x, y);
    }
}
