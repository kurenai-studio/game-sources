package dev.luchoc.littlespaceship.game.ui;

import com.badlogic.gdx.graphics.Color;

/**
 * {@code ls32}, {@code docs/design/01-palette.md}, as libGDX colours. One constant per id so the
 * HUD and the screens quote the same closed set the sprites already do, instead of a colour typed
 * from memory that quietly drifts from the document.
 *
 * <p>Only the ids actually used outside gameplay sprites are declared here: HUD plates, screen
 * frames, menu text, sliders. Sprite colours stay local to {@link
 * dev.luchoc.littlespaceship.game.adapter.render.PlaceholderAtlas}, which already names them.
 */
public final class Palette {

    public static final Color N0 = fromHex(0x0B0E14);
    public static final Color N1 = fromHex(0x161B26);
    public static final Color N2 = fromHex(0x242C3B);
    public static final Color N3 = fromHex(0x3B475C);
    public static final Color N4 = fromHex(0x5C6B85);
    public static final Color N5 = fromHex(0x8D9CB5);
    public static final Color N6 = fromHex(0xC9D6E8);
    public static final Color N7 = Color.WHITE;
    public static final Color C1 = fromHex(0x2FBFD4);
    public static final Color C2 = fromHex(0x9DF2FA);
    public static final Color W3 = fromHex(0xE5822C);
    public static final Color W4 = fromHex(0xFFC94A);
    public static final Color F1 = fromHex(0xFFF6D9);
    public static final Color G2 = fromHex(0x34A75C);
    public static final Color G3 = fromHex(0x7FE08A);

    private Palette() {
    }

    private static Color fromHex(int rgb) {
        return new Color(
            ((rgb >>> 16) & 0xFF) / 255f,
            ((rgb >>> 8) & 0xFF) / 255f,
            (rgb & 0xFF) / 255f,
            1f);
    }
}
