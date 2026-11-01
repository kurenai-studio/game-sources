package com.micro1.mooncourier;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Align;

/**
 * Stateless drawing helpers shared by every screen. Shape helpers assume the {@link ShapeRenderer}
 * is already in {@code ShapeType.Filled} mode; text helpers assume the {@link SpriteBatch} has been
 * begun. Everything is procedural (asset-free): shapes from {@code ShapeRenderer}, text from the
 * built-in {@code BitmapFont}.
 */
public final class Draw {

    private Draw() {
    }

    // ------------------------------------------------------------------ primitives

    public static void rect(ShapeRenderer s, float x, float y, float w, float h, Color c) {
        s.setColor(c);
        s.rect(x, y, w, h);
    }

    public static void circle(ShapeRenderer s, float x, float y, float r, Color c) {
        s.setColor(c);
        s.circle(x, y, r, 48);
    }

    /** A filled panel with a border frame (used for HUD boxes and result cards). */
    public static void panel(ShapeRenderer s, float x, float y, float w, float h,
                             Color fill, Color border) {
        s.setColor(fill);
        s.rect(x, y, w, h);
        frame(s, x, y, w, h, 2f, border);
    }

    /** A hollow rectangular frame of the given thickness (four thin filled rects). */
    public static void frame(ShapeRenderer s, float x, float y, float w, float h,
                             float t, Color c) {
        s.setColor(c);
        s.rect(x, y, w, t);             // bottom
        s.rect(x, y + h - t, w, t);     // top
        s.rect(x, y, t, h);             // left
        s.rect(x + w - t, y, t, h);     // right
    }

    // ------------------------------------------------------------------ backgrounds

    /** Deep-space backdrop with a star field, Earth, and a lunar horizon strip along the bottom. */
    public static void spaceBackground(ShapeRenderer s, Assets a) {
        s.setColor(Palette.SPACE);
        s.rect(0f, 0f, 1280f, 720f);
        for (int i = 0; i < a.stars.length; i += 3) {
            float b = a.stars[i + 2];
            s.setColor(b, b, b + 0.05f, 1f);
            float size = b > 0.8f ? 2.2f : 1.4f;
            s.rect(a.stars[i], a.stars[i + 1], size, size);
        }
        earth(s, 1178f, 602f, 54f);
        // Lunar horizon strip along the bottom.
        s.setColor(Palette.REGOLITH_DARK);
        s.rect(0f, 0f, 1280f, 130f);
        for (int i = 0; i < a.speckles.length; i += 3) {
            if (a.speckles[i + 1] > 118f) {
                continue;
            }
            s.setColor(a.speckles[i + 2] > 0.5f ? Palette.REGOLITH_LIGHT : Palette.REGOLITH);
            s.rect(a.speckles[i], a.speckles[i + 1] * (110f / 720f), 2.4f, 2.4f);
        }
    }

    /** Flat top-down lunar surface filling the whole play area, with fixed speckle texture. */
    public static void moonSurface(ShapeRenderer s, Assets a) {
        s.setColor(Palette.REGOLITH);
        s.rect(0f, 0f, 1280f, 720f);
        for (int i = 0; i < a.speckles.length; i += 3) {
            s.setColor(a.speckles[i + 2] > 0.5f ? Palette.REGOLITH_LIGHT : Palette.REGOLITH_DARK);
            s.rect(a.speckles[i], a.speckles[i + 1], 2.6f, 2.6f);
        }
    }

    public static void earth(ShapeRenderer s, float x, float y, float r) {
        s.setColor(Palette.EARTH_OCEAN);
        s.circle(x, y, r, 48);
        s.setColor(Palette.EARTH_LAND);
        s.circle(x - r * 0.3f, y + r * 0.2f, r * 0.34f, 24);
        s.circle(x + r * 0.32f, y - r * 0.25f, r * 0.28f, 24);
        s.circle(x + r * 0.1f, y + r * 0.4f, r * 0.20f, 24);
        s.setColor(Palette.EARTH_CLOUD);
        s.circle(x - r * 0.45f, y - r * 0.35f, r * 0.16f, 16);
        s.circle(x + r * 0.5f, y + r * 0.35f, r * 0.14f, 16);
    }

    // ------------------------------------------------------------------ world objects

    public static void obstacle(ShapeRenderer s, Obstacle o) {
        if (o.type == Obstacle.Type.CRATER) {
            s.setColor(Palette.CRATER_RIM);
            s.circle(o.x, o.y, o.radius, 32);
            s.setColor(Palette.CRATER_PIT);
            s.circle(o.x, o.y, o.radius - 5f, 32);
            // Off-centre highlight to suggest depth.
            s.setColor(Palette.REGOLITH_DARK);
            s.circle(o.x + o.radius * 0.18f, o.y + o.radius * 0.18f, o.radius * 0.55f, 24);
        } else {
            // A jagged grey rock: a filled polygon of radius-jittered vertices around the centre.
            int n = 9;
            s.setColor(Palette.ROCK);
            for (int i = 0; i < n; i++) {
                int j = (i + 1) % n;
                float angleA = MathUtils.PI2 * i / n;
                float angleB = MathUtils.PI2 * j / n;
                float radiusA = o.radius * rockJitter(o.seed, i);
                float radiusB = o.radius * rockJitter(o.seed, j);
                s.triangle(o.x, o.y,
                    o.x + MathUtils.cos(angleA) * radiusA,
                    o.y + MathUtils.sin(angleA) * radiusA,
                    o.x + MathUtils.cos(angleB) * radiusB,
                    o.y + MathUtils.sin(angleB) * radiusB);
            }
            s.setColor(Palette.ROCK_SHADE);
            s.circle(o.x - o.radius * 0.25f, o.y - o.radius * 0.25f, o.radius * 0.35f, 16);
        }
    }

    private static float fract(float f) {
        return f - (float) Math.floor(f);
    }

    private static float rockJitter(int seed, int vertex) {
        return 0.72f + 0.28f * fract(Math.abs(MathUtils.sin(seed + vertex * 1.7f)));
    }

    /** The cargo crate as a strapped tan box, centred at (x, y). */
    public static void crate(ShapeRenderer s, float x, float y) {
        float hw = 27f;
        float hh = 23f;
        s.setColor(Palette.CRATE_DARK);
        s.rect(x - hw - 2f, y - hh - 2f, (hw + 2f) * 2f, (hh + 2f) * 2f);
        s.setColor(Palette.CRATE);
        s.rect(x - hw, y - hh, hw * 2f, hh * 2f);
        s.setColor(Palette.CRATE_STRAP);
        s.rect(x - 3f, y - hh, 6f, hh * 2f);           // vertical strap
        s.rect(x - hw, y - 3f, hw * 2f, 6f);           // horizontal strap
        s.setColor(Palette.CRATE_DARK);
        float b = 4f;
        s.rect(x - hw, y - hh, b, b);
        s.rect(x + hw - b, y - hh, b, b);
        s.rect(x - hw, y + hh - b, b, b);
        s.rect(x + hw - b, y + hh - b, b, b);
    }

    /** The delivery pad: a yellow-ringed asphalt octagon with a white centre ring and edge lights. */
    public static void deliveryPad(ShapeRenderer s, float x, float y, float r) {
        filledOctagon(s, x, y, r, Palette.PAD_YELLOW);            // yellow border ring...
        filledOctagon(s, x, y, r - 7f, Palette.PAD_ASPHALT);     // ...cut back to asphalt
        // Inner white ring.
        s.setColor(Palette.PAD_MARK);
        s.circle(x, y, r * 0.60f, 40);
        s.setColor(Palette.PAD_ASPHALT);
        s.circle(x, y, r * 0.60f - 4f, 40);
        // Chevron approach marks at top and bottom.
        s.setColor(Palette.PAD_MARK);
        s.rect(x - 3f, y + r * 0.60f, 6f, r * 0.24f);
        s.rect(x - 3f, y - r * 0.84f, 6f, r * 0.24f);
        // Edge lights at the eight vertices.
        s.setColor(Palette.PAD_YELLOW);
        for (int i = 0; i < 8; i++) {
            float angle = MathUtils.PI / 8f + i * MathUtils.PI / 4f;
            s.circle(x + MathUtils.cos(angle) * (r - 3.5f),
                y + MathUtils.sin(angle) * (r - 3.5f), 3.2f, 10);
        }
    }

    public static void filledOctagon(ShapeRenderer s, float cx, float cy, float r, Color c) {
        s.setColor(c);
        for (int i = 0; i < 8; i++) {
            float angleA = MathUtils.PI / 8f + i * MathUtils.PI / 4f;
            float angleB = MathUtils.PI / 8f + (i + 1) * MathUtils.PI / 4f;
            s.triangle(cx, cy,
                cx + MathUtils.cos(angleA) * r,
                cy + MathUtils.sin(angleA) * r,
                cx + MathUtils.cos(angleB) * r,
                cy + MathUtils.sin(angleB) * r);
        }
    }

    /** The spacecraft, pointing up, centred at (x, y). Draws a thruster flame when {@code flame}. */
    public static void ship(ShapeRenderer s, float x, float y, boolean flame) {
        if (flame) {
            s.setColor(Palette.FLAME);
            s.triangle(x - 7f, y - 18f, x + 7f, y - 18f, x, y - 36f);
            s.setColor(Palette.FLAME_CORE);
            s.triangle(x - 3.5f, y - 18f, x + 3.5f, y - 18f, x, y - 27f);
        }
        // Fins.
        s.setColor(Palette.SHIP_STRIPE);
        s.triangle(x - 12f, y - 4f, x - 22f, y - 18f, x - 12f, y - 18f);
        s.triangle(x + 12f, y - 4f, x + 22f, y - 18f, x + 12f, y - 18f);
        // Lower hull.
        s.setColor(Palette.SHIP_SHADE);
        s.rect(x - 12f, y - 18f, 24f, 10f);
        // Body.
        s.setColor(Palette.SHIP_BODY);
        s.rect(x - 12f, y - 10f, 24f, 20f);
        // Nose.
        s.triangle(x - 12f, y + 8f, x + 12f, y + 8f, x, y + 26f);
        // Cockpit.
        s.setColor(Palette.SHIP_COCKPIT);
        s.circle(x, y + 8f, 5.2f, 16);
        // Engine bell.
        s.setColor(Palette.SHIP_SHADE);
        s.rect(x - 6f, y - 22f, 12f, 5f);
    }

    // ------------------------------------------------------------------ HUD widgets

    /** A segmented fuel bar; colour shifts green -> yellow -> red as the level drops. */
    public static void fuelBar(ShapeRenderer s, float x, float y, float w, float h, int percent) {
        int segments = 10;
        float gap = 3f;
        float segW = (w - gap * (segments - 1)) / segments;
        int filled = Math.round(percent / 10f);
        Color fill = percent > 50 ? Palette.FUEL_GREEN
            : percent > 25 ? Palette.FUEL_YELLOW : Palette.FUEL_RED;
        for (int i = 0; i < segments; i++) {
            float sx = x + i * (segW + gap);
            s.setColor(i < filled ? fill : Palette.FUEL_EMPTY);
            s.rect(sx, y, segW, h);
        }
    }

    /** Minimap: maps the play field into a small box with ship / cargo / pad markers. */
    public static void minimap(ShapeRenderer s, float x, float y, float w, float h, MissionWorld world) {
        float mnx = MissionWorld.PLAY_MIN_X;
        float mny = MissionWorld.PLAY_MIN_Y;
        float rangeX = MissionWorld.PLAY_MAX_X - mnx;
        float rangeY = MissionWorld.PLAY_MAX_Y - mny;
        float pad = 10f;
        // Pad marker (green).
        s.setColor(Palette.GREEN);
        float px = x + pad + (MissionWorld.PAD_X - mnx) / rangeX * (w - 2 * pad);
        float py = y + pad + (MissionWorld.PAD_Y - mny) / rangeY * (h - 2 * pad);
        s.circle(px, py, 5f, 12);
        // Cargo marker (yellow) while uncollected.
        if (!world.isCargoCollected()) {
            s.setColor(Palette.YELLOW);
            float cx = x + pad + (MissionWorld.CRATE_X - mnx) / rangeX * (w - 2 * pad);
            float cy = y + pad + (MissionWorld.CRATE_Y - mny) / rangeY * (h - 2 * pad);
            s.rect(cx - 4f, cy - 4f, 8f, 8f);
        }
        // Ship marker (white).
        s.setColor(Palette.WHITE);
        float sx = x + pad + (world.getShipX() - mnx) / rangeX * (w - 2 * pad);
        float sy = y + pad + (world.getShipY() - mny) / rangeY * (h - 2 * pad);
        s.circle(sx, sy, 4.5f, 12);
    }

    // ------------------------------------------------------------------ text

    public static void textLeft(SpriteBatch b, BitmapFont f, String str, float x, float yTop, Color c) {
        f.setColor(c);
        f.draw(b, str, x, yTop);
    }

    public static void textCentered(SpriteBatch b, BitmapFont f, GlyphLayout l, String str,
                                    float cx, float yTop, Color c) {
        f.setColor(c);
        l.setText(f, str);
        f.draw(b, l, cx - l.width / 2f, yTop);
    }

    public static void textRight(SpriteBatch b, BitmapFont f, GlyphLayout l, String str,
                                 float rightX, float yTop, Color c) {
        f.setColor(c);
        l.setText(f, str);
        f.draw(b, l, rightX - l.width, yTop);
    }

    /** Centred, word-wrapped block centred on {@code cx} within {@code width}. */
    public static void textWrapped(SpriteBatch b, BitmapFont f, GlyphLayout l, String str,
                                   float cx, float yTop, float width, Color c) {
        l.setText(f, str, c, width, Align.center, true);
        f.draw(b, l, cx - width / 2f, yTop);
    }

    /** Width of a string in the given font (for manual layout). */
    public static float widthOf(BitmapFont f, GlyphLayout l, String str) {
        l.setText(f, str);
        return l.width;
    }
}
