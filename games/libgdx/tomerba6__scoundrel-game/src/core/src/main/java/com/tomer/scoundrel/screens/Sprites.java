package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.TextureData;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;
import com.badlogic.gdx.utils.GdxRuntimeException;

import java.util.HashMap;
import java.util.Map;

/**
 * The packed pixel art, loaded once and shared. Owns the atlas and
 * is the only thing that should: the source PNGs live outside the asset path
 * precisely so nothing can load a sprite as a loose file and get a smoothed
 * texture.
 *
 * <p>Region names are the art's contract — {@code creature_<value>_<name>_<suit>},
 * with idle frames adding {@code _idle_1}…{@code _idle_5} so
 * {@link #frames(String)} returns the five in order.
 */
public final class Sprites implements Disposable {

    /** Every sprite is 64×64, and only integer multiples of it may be drawn. */
    public static final int SIZE = 64;

    private final TextureAtlas atlas;
    private final Texture rimPage;
    private final Texture hurtPage;
    private final Map<String, TextureRegion> rims = new HashMap<>();
    private final Map<String, TextureRegion> hurts = new HashMap<>();
    /**
     * The atlas page kept in memory so effects can read a sprite's pixels at
     * runtime — the bottle's tilt stages are built when a potion is drunk
     * rather than for all nine at load. 4MB, against 27 regions never used.
     */
    private final Pixmap page;

    /**
     * Loads the packed atlas, checks it is nearest-filtered, keeps its page in
     * memory, and generates the rim and hurt pages from it.
     *
     * @throws GdxRuntimeException if the atlas is missing or not nearest-filtered
     * @see TextureAtlas
     */
    public Sprites() {
        atlas = new TextureAtlas(Gdx.files.internal("sprites/sprites.atlas"));
        assertNearestFiltering();
        TextureData data = atlas.getTextures().first().getTextureData();
        if (!data.isPrepared()) {
            data.prepare();
        }
        page = data.consumePixmap();
        rimPage = buildDerived(RimMask::generate, rims);
        hurtPage = buildDerived(HurtMask::generate, hurts);
    }

    /** A per-sprite pixel rule, applied to build a derived page. */
    private interface Rule {
        int[] apply(int[] argb, int width, int height);
    }

    /**
     * Builds a derived frame for every creature into one page laid out exactly
     * like the atlas, so the result shares its sprite's coordinates and costs
     * one texture rather than 26. Generating beats shipping: it keeps 52 files
     * out of the atlas and cannot fall out of step if a sprite is redrawn.
     */
    private Texture buildDerived(Rule rule, Map<String, TextureRegion> into) {
        Pixmap rimmed = new Pixmap(page.getWidth(), page.getHeight(), Pixmap.Format.RGBA8888);
        rimmed.setBlending(Pixmap.Blending.None);

        Array<TextureAtlas.AtlasRegion> creatures = new Array<>();
        for (TextureAtlas.AtlasRegion region : atlas.getRegions()) {
            // Only creatures flash; weapons and potions are never struck. The
            // base sprite carries the outline, not the individual idle frames,
            // which the atlas groups under a name ending in "_idle".
            if (region.name.startsWith("creature_") && !region.name.endsWith("_idle")) {
                creatures.add(region);
            }
        }

        for (TextureAtlas.AtlasRegion region : creatures) {
            int w = region.getRegionWidth();
            int h = region.getRegionHeight();
            int[] src = new int[w * h];
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    src[y * w + x] = rgbaToArgb(
                            page.getPixel(region.getRegionX() + x, region.getRegionY() + y));
                }
            }
            int[] out = rule.apply(src, w, h);
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    rimmed.drawPixel(region.getRegionX() + x, region.getRegionY() + y,
                            argbToRgba(out[y * w + x]));
                }
            }
        }

        Texture texture = new Texture(rimmed);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        for (TextureAtlas.AtlasRegion region : creatures) {
            into.put(region.name, new TextureRegion(texture, region.getRegionX(),
                    region.getRegionY(), region.getRegionWidth(), region.getRegionHeight()));
        }
        rimmed.dispose();
        return texture;
    }

    /**
     * A named region's pixels in ARGB, for effects that transform a sprite.
     *
     * @param regionName the region's exact name in the atlas
     * @return a new array, row-major from the top, alpha in the high byte
     * @throws GdxRuntimeException if there is no region by that name
     */
    public int[] pixelsOf(String regionName) {
        TextureAtlas.AtlasRegion region = atlas.findRegion(regionName);
        if (region == null) {
            throw new GdxRuntimeException("no sprite region named '" + regionName + "'");
        }
        int w = region.getRegionWidth();
        int h = region.getRegionHeight();
        int[] out = new int[w * h];
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                out[y * w + x] = rgbaToArgb(
                        page.getPixel(region.getRegionX() + x, region.getRegionY() + y));
            }
        }
        return out;
    }

    /**
     * Builds a texture from ARGB pixels, nearest-filtered like everything else.
     *
     * @param argb   the pixels, row-major from the top, alpha in the high byte
     * @param width  the image's width in pixels
     * @param height the image's height in pixels
     * @return a new texture, which the caller owns and must dispose
     */
    public static Texture textureFrom(int[] argb, int width, int height) {
        Pixmap pixmap = new Pixmap(width, height, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                pixmap.drawPixel(x, y, argbToRgba(argb[y * width + x]));
            }
        }
        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pixmap.dispose();
        return texture;
    }

    /** Pixmap stores RGBA8888; RimMask works in ARGB like every other Java image. */
    private static int rgbaToArgb(int rgba) {
        return (rgba >>> 8) | (rgba << 24);
    }

    private static int argbToRgba(int argb) {
        return (argb << 8) | (argb >>> 24);
    }

    /**
     * The cream outline for a creature's base sprite, generated at load. Null
     * for anything that has none — weapons and potions are never struck.
     *
     * @param regionName a base region's name, as {@link CardSprites#regionName} gives it
     * @return the outline, on the shared rim page, or null
     */
    public TextureRegion rim(String regionName) {
        return rims.get(regionName);
    }

    /**
     * The frame a creature holds while it is struck: brightened two steps up its
     * own ramp with the outline over it. Null for anything never struck.
     *
     * @param regionName a base region's name, as {@link CardSprites#regionName} gives it
     * @return the struck frame, on the shared hurt page, or null
     */
    public TextureRegion hurt(String regionName) {
        return hurts.get(regionName);
    }

    /**
     * The whole art direction rests on nearest-neighbour sampling: these are
     * hand-placed pixels on a locked 80-colour ramp, and any smoothing invents
     * colours that are not in it. The atlas file carries {@code filter: Nearest,
     * Nearest} and libGDX applies it on load, but a wrong pack setting or a
     * texture swapped in later would only show up as art that looks slightly
     * soft — easy to blame on something else. Fail loudly instead.
     */
    private void assertNearestFiltering() {
        for (Texture texture : atlas.getTextures()) {
            if (texture.getMinFilter() != Texture.TextureFilter.Nearest
                    || texture.getMagFilter() != Texture.TextureFilter.Nearest) {
                throw new GdxRuntimeException("sprite atlas is not nearest-filtered ("
                        + texture.getMinFilter() + "/" + texture.getMagFilter()
                        + ") — pixel art would be blurred");
            }
        }
    }

    /**
     * A single region by its exact name; fails loudly rather than drawing nothing.
     *
     * @param name the region's exact name in the atlas
     * @return the region, owned by the atlas
     * @throws GdxRuntimeException if there is no region by that name
     */
    public TextureRegion region(String name) {
        TextureRegion region = atlas.findRegion(name);
        if (region == null) {
            throw new GdxRuntimeException("no sprite region named '" + name + "'");
        }
        return region;
    }

    /**
     * The frames of an animation cycle, in index order — pass the stem without
     * the trailing index, e.g. {@code "creature_02_cellar_rat_clubs_idle"}.
     *
     * @param stem the frames' shared name, without the index
     * @return a new array of the frames, index 1 first; five for every creature
     * @throws GdxRuntimeException if no frames have that name
     * @see TextureAtlas#findRegions(String)
     */
    public Array<TextureRegion> frames(String stem) {
        Array<TextureAtlas.AtlasRegion> found = atlas.findRegions(stem);
        if (found.size == 0) {
            throw new GdxRuntimeException("no sprite frames named '" + stem + "'");
        }
        return new Array<>(found);
    }

    @Override
    public void dispose() {
        rimPage.dispose();
        hurtPage.dispose();
        page.dispose();
        atlas.dispose();
    }
}
