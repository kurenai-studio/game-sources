package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Disposable;

/**
 * The shapes the effects draw that are not sprites: the two halves a card is
 * cleaved into, the bone bar that cuts it, the eight-point burst a blow
 * throws, and the bottle a potion card collapses into.
 *
 * <p>All three are built as pixel masks at load rather than drawn with rotation
 * or a shader. The bar in particular is generated already diagonal instead of
 * being a straight bar turned 56° at draw time — rotating it would resample its
 * edges into colours that are not on the ramp, which is the one thing the art
 * cannot tolerate.
 */
final class EffectArt implements Disposable {

    /** The cleaved card's cut faces. */
    private static final int UPPER_FILL = 0x3a1d18;
    private static final int LOWER_FILL = 0x2c1512;
    private static final int EDGE = 0x0a0806;
    private static final int BONE = 0xe8ddc7;

    /** The bar is drawn long enough to cross the card corner to corner. */
    private static final int BAR_THICKNESS = 8;

    /** The bottle. */
    private static final int GLASS = 0x5d8a4a;
    private static final int GLASS_SHADE = 0x507641;
    private static final int BOTTLE_EDGE = 0x35291f;
    private static final int CORK = 0x9a8b70;
    /** The bottle's texture is this many pixels square. */
    static final int BOTTLE_SIZE = 48;

    /**
     * The classic 4×4 ordered (Bayer) matrix. Each cell's number is the level
     * at which that pixel goes dark, so raising the level turns pixels off in a
     * fixed, evenly-spread order rather than dimming them all together.
     */
    private static final int[] BAYER = {
        0, 8, 2, 10,
        12, 4, 14, 6,
        3, 11, 1, 9,
        15, 7, 13, 5,
    };

    private final Texture[] ditherTextures;
    private final TextureRegion[] dither;

    private final Texture upperTexture;
    private final Texture lowerTexture;
    private final Texture barTexture;
    private final Texture starTexture;
    private final Texture bottleTexture;
    private final Texture spentTexture;
    private final int[] bottlePixels;

    private final TextureRegion upper;
    private final TextureRegion lower;
    private final TextureRegion bar;
    private final TextureRegion star;
    private final TextureRegion bottle;
    private final TextureRegion spent;

    /**
     * Builds every effect texture, {@code Nearest}-filtered, at the card's size.
     *
     * @param cardWidth  a card's width in pixels, which the cleave and the bar span
     * @param cardHeight a card's height in pixels
     */
    EffectArt(int cardWidth, int cardHeight) {
        upperTexture = triangle(cardWidth, cardHeight, true);
        lowerTexture = triangle(cardWidth, cardHeight, false);
        barTexture = diagonalBar(cardWidth, cardHeight);
        starTexture = burst(Barehanded.STAR_BOX);
        bottlePixels = flaskPixels(BOTTLE_SIZE);
        bottleTexture = Sprites.textureFrom(bottlePixels, BOTTLE_SIZE, BOTTLE_SIZE);
        // The wasted bottle is the same pixels drained to bone, generated here
        // rather than tinted at draw time — a multiply blend would land colours
        // between the ramp steps.
        spentTexture = Sprites.textureFrom(
                SpentMask.generate(bottlePixels), BOTTLE_SIZE, BOTTLE_SIZE);
        upper = new TextureRegion(upperTexture);
        lower = new TextureRegion(lowerTexture);
        bar = new TextureRegion(barTexture);
        star = new TextureRegion(starTexture);
        bottle = new TextureRegion(bottleTexture);
        spent = new TextureRegion(spentTexture);

        // One 4x4 tile per level, wrapped so a single draw covers the screen.
        ditherTextures = new Texture[DeathCinematic.DITHER_LEVELS + 1];
        dither = new TextureRegion[ditherTextures.length];
        for (int level = 0; level < ditherTextures.length; level++) {
            ditherTextures[level] = ditherTile(level);
            dither[level] = new TextureRegion(ditherTextures[level]);
        }
    }

    /**
     * The screen-death pattern at a given level, as a 4×4 tile set to repeat.
     * Drawn once across the whole stage with the region sized in tiles, so the
     * pattern lands on the pixel grid however big the stage is.
     *
     * @param level       how many of the sixteen cells are dark; clamped to the levels built
     * @param stageWidth  the area to cover, in pixels
     * @param stageHeight the area to cover, in pixels
     * @return the shared region for that level, resized to repeat across the stage
     */
    TextureRegion ditherAt(int level, int stageWidth, int stageHeight) {
        TextureRegion region = dither[Math.max(0, Math.min(dither.length - 1, level))];
        region.setRegion(0, 0, stageWidth / 4, stageHeight / 4);
        return region;
    }

    private static Texture ditherTile(int level) {
        Pixmap pixmap = new Pixmap(4, 4, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        for (int y = 0; y < 4; y++) {
            for (int x = 0; x < 4; x++) {
                // Opaque black where this cell's threshold has been crossed,
                // fully clear everywhere else. No partial alpha anywhere: that
                // is what makes it a pattern rather than a fade.
                boolean dark = BAYER[y * 4 + x] < level;
                pixmap.drawPixel(x, y, dark ? 0x000000ff : 0x00000000);
            }
        }
        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        texture.setWrap(Texture.TextureWrap.Repeat, Texture.TextureWrap.Repeat);
        pixmap.dispose();
        return texture;
    }

    /**
     * The half above-left of the cut, or the half below-right of it.
     *
     * @return the upper half of a cleaved card, card-sized
     */
    TextureRegion upper() {
        return upper;
    }

    /**
     * The half below-right of the cut.
     *
     * @return the lower half of a cleaved card, card-sized
     */
    TextureRegion lower() {
        return lower;
    }

    /**
     * The bone bar that cuts the card, already lying along the diagonal.
     *
     * @return a card-sized region, clear but for the bar
     */
    TextureRegion bar() {
        return bar;
    }

    /**
     * The eight-point burst a bare-handed blow throws.
     *
     * @return a {@link Barehanded#STAR_BOX}-pixel square region
     */
    TextureRegion star() {
        return star;
    }

    /**
     * The bottle a potion card collapses into.
     *
     * @return a {@link #BOTTLE_SIZE}-pixel square region
     */
    TextureRegion bottle() {
        return bottle;
    }

    /**
     * The same bottle with the colour drained out, for a potion that is wasted.
     *
     * @return a {@link #BOTTLE_SIZE}-pixel square region
     */
    TextureRegion spentBottle() {
        return spent;
    }

    /**
     * One half of the cleaved card: a filled triangle with a dark cut edge. The
     * cut runs top-right to bottom-left, so the upper half is the top-left
     * triangle and the lower half the bottom-right one.
     */
    private static Texture triangle(int w, int h, boolean upperHalf) {
        Pixmap pixmap = new Pixmap(w, h, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        pixmap.setColor(0);
        pixmap.fill();

        // Draw the edge colour first, then the fill inset by the border, so the
        // cut face reads as a dark lip on every side including the diagonal.
        pixmap.setColor(new Color((EDGE << 8) | 0xff));
        fillHalf(pixmap, w, h, upperHalf, 0);
        pixmap.setColor(new Color(((upperHalf ? UPPER_FILL : LOWER_FILL) << 8) | 0xff));
        fillHalf(pixmap, w, h, upperHalf, 4);

        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pixmap.dispose();
        return texture;
    }

    /**
     * Fills one side of the corner-to-corner diagonal, inset by {@code inset}
     * pixels on all three sides. Done per row rather than with fillTriangle so
     * the inset is exact and every edge lands on a whole pixel.
     */
    private static void fillHalf(Pixmap pixmap, int w, int h, boolean upperHalf, int inset) {
        for (int y = inset; y < h - inset; y++) {
            // The cut: x/w + y/h = 1. Rows above it are wider on the left.
            int cut = Math.round(w * (1f - y / (float) h));
            int from = upperHalf ? inset : cut + inset;
            int to = upperHalf ? cut - inset : w - inset;
            if (to > from) {
                pixmap.drawLine(from, y, to - 1, y);
            }
        }
    }

    /**
     * The bottle a potion card collapses into — a squat body with a heavy dark
     * lip, a neck and a cork, drawn as flat rects the way the card frames are.
     * Not the potion sprite: this is furniture, and it has to read at 24px on
     * its way to the health bar where a 64px illustration would turn to mush.
     */
    private static int[] flaskPixels(int size) {
        Pixmap pixmap = new Pixmap(size, size, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        pixmap.setColor(0);
        pixmap.fill();

        int unit = size / 12;                 // 4 at the design size
        int neckW = unit * 2;
        int neckX = (size - neckW) / 2;

        // Cork, then neck, then the body beneath them.
        pixmap.setColor(new Color((CORK << 8) | 0xff));
        pixmap.fillRectangle(neckX - unit / 2, 0, neckW + unit, unit * 2);
        pixmap.setColor(new Color((BOTTLE_EDGE << 8) | 0xff));
        pixmap.fillRectangle(neckX, unit * 2, neckW, unit * 2);

        int bodyY = unit * 4;
        int bodyH = size - bodyY;
        pixmap.fillRectangle(unit, bodyY, size - unit * 2, bodyH);
        pixmap.setColor(new Color((GLASS << 8) | 0xff));
        pixmap.fillRectangle(unit * 2, bodyY + unit, size - unit * 4, bodyH - unit * 2);
        // A shade down the left, so the glass reads as round rather than flat.
        pixmap.setColor(new Color((GLASS_SHADE << 8) | 0xff));
        pixmap.fillRectangle(unit * 2, bodyY + unit, unit, bodyH - unit * 2);

        int[] out = new int[size * size];
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                int rgba = pixmap.getPixel(x, y);
                out[y * size + x] = (rgba >>> 8) | (rgba << 24);
            }
        }
        pixmap.dispose();
        return out;
    }

    /**
     * The eight-point burst: four bars in a box, drawn as pixels rather than
     * geometry. The two straight arms are plain rects; the diagonals are
     * staircases of 8×8 blocks, each offset one block right and one block down
     * from the last. That is exactly 45° and perfectly grid-aligned, where a
     * rotated rect would resample into soft grey edges — the worst thing that
     * can be done to a pixel sprite.
     */
    private static Texture burst(int box) {
        Pixmap pixmap = new Pixmap(box, box, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        pixmap.setColor(0);
        pixmap.fill();
        pixmap.setColor(new Color((BONE << 8) | 0xff));

        int arm = box / 10;                 // 8 at the design size
        int mid = (box - arm) / 2;          // 36
        pixmap.fillRectangle(0, mid, box, arm);
        pixmap.fillRectangle(mid, 0, arm, box);

        // Three blocks each side of centre covers the 52px diagonal arms.
        for (int step = -3; step <= 3; step++) {
            pixmap.fillRectangle(mid + step * arm, mid + step * arm, arm, arm);
            pixmap.fillRectangle(mid + step * arm, mid - step * arm, arm, arm);
        }

        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pixmap.dispose();
        return texture;
    }

    /** A bone bar already lying along the cut, so it never has to be rotated. */
    private static Texture diagonalBar(int w, int h) {
        Pixmap pixmap = new Pixmap(w, h, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        pixmap.setColor(0);
        pixmap.fill();
        pixmap.setColor(new Color((BONE << 8) | 0xff));
        for (int y = 0; y < h; y++) {
            int cut = Math.round(w * (1f - y / (float) h));
            int from = Math.max(0, cut - BAR_THICKNESS / 2);
            int to = Math.min(w, cut + BAR_THICKNESS / 2);
            if (to > from) {
                pixmap.drawLine(from, y, to - 1, y);
            }
        }
        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pixmap.dispose();
        return texture;
    }

    @Override
    public void dispose() {
        upperTexture.dispose();
        lowerTexture.dispose();
        barTexture.dispose();
        starTexture.dispose();
        bottleTexture.dispose();
        spentTexture.dispose();
        for (Texture texture : ditherTextures) {
            texture.dispose();
        }
    }
}
