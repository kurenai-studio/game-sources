package com.micro1.mooncourier;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * A simple rectangular menu button: a coloured face with a border and a centred label. Hit-testing
 * and hover state are driven by the owning screen each frame; drawing is split into a shape pass
 * (the face) and a text pass (the label) so it composes with the screens' two-pass rendering.
 */
public final class Button {

    public final float x;
    public final float y;
    public final float w;
    public final float h;
    public final String label;
    public final Color face;
    public final Color border;
    public final Color textColor;
    public boolean hovered;

    public Button(float x, float y, float w, float h, String label,
                  Color face, Color border, Color textColor) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.label = label;
        this.face = face;
        this.border = border;
        this.textColor = textColor;
    }

    public boolean contains(float px, float py) {
        return px >= x && px <= x + w && py >= y && py <= y + h;
    }

    public float centerX() {
        return x + w / 2f;
    }

    public float centerY() {
        return y + h / 2f;
    }

    /** Shape pass: the button face plus border, brightened slightly while hovered. */
    public void drawFace(ShapeRenderer s) {
        Color f = face;
        if (hovered) {
            s.setColor(Math.min(1f, f.r + 0.12f), Math.min(1f, f.g + 0.12f),
                Math.min(1f, f.b + 0.12f), f.a);
        } else {
            s.setColor(f);
        }
        s.rect(x, y, w, h);
        Draw.frame(s, x, y, w, h, 2.5f, border);
    }

    /** Text pass: the centred label. */
    public void drawLabel(SpriteBatch b, BitmapFont font, GlyphLayout layout) {
        font.setColor(textColor);
        layout.setText(font, label);
        font.draw(b, layout, centerX() - layout.width / 2f, centerY() + layout.height / 2f);
    }
}
