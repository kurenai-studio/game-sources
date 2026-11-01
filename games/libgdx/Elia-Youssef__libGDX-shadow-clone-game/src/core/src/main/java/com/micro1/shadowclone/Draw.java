package com.micro1.shadowclone;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * Small drawing helpers shared by {@link WorldRenderer} and {@link Hud}. All filled calls assume an
 * active {@code ShapeRenderer.begin(Filled)} pass; all border/line calls assume a {@code Line} pass.
 * Blending must be enabled by the caller so the translucent glow layers read correctly.
 */
public final class Draw {

    private Draw() {}

    public static void fill(ShapeRenderer sr, float x, float y, float w, float h, Color c) {
        sr.setColor(c);
        sr.rect(x, y, w, h);
    }

    /** A soft neon glow: a few translucent rectangles growing outward from the base rect. */
    public static void glow(ShapeRenderer sr, float x, float y, float w, float h, Color c, float spread) {
        for (int i = 3; i >= 1; i--) {
            float g = spread * i;
            sr.setColor(c.r, c.g, c.b, c.a * 0.10f);
            sr.rect(x - g, y - g, w + g * 2f, h + g * 2f);
        }
    }

    public static void border(ShapeRenderer sr, float x, float y, float w, float h, Color c) {
        sr.setColor(c);
        sr.rect(x, y, w, h);
    }

    /** A filled HUD panel (dark translucent fill). Draw its border in the Line pass. */
    public static void panel(ShapeRenderer sr, float x, float y, float w, float h, Color fill) {
        sr.setColor(fill);
        sr.rect(x, y, w, h);
    }

    /** A filled triangle pointing right (or left for a negative width): the conveyor chevrons. */
    public static void triRight(ShapeRenderer sr, float leftX, float cy, float width, float halfH, Color c) {
        sr.setColor(c);
        sr.triangle(leftX, cy - halfH, leftX, cy + halfH, leftX + width, cy);
    }
}
