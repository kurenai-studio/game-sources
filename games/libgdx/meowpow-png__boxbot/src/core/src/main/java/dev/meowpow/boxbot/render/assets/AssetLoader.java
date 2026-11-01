package dev.meowpow.boxbot.render.assets;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;
import com.badlogic.gdx.utils.Disposable;

import java.util.*;

/**
 * Loads and owns the game's rendering assets.
 */
public final class AssetLoader implements Disposable {

    private static final String ATLAS_PATH = "atlas/sprites.atlas";
    private static final String DARKNESS_OVERLAY_PATH = "overlays/darkness.png";
    private static final String HEADLIGHT_OVERLAY_PATH = "overlays/headlight.png";
    private static final String MAP_PATH = "maps/map.tmx";

    private final List<BakedFont> bakedFonts = new ArrayList<>();
    private final Map<FontFamily, FreeTypeFontGenerator> fontGenerators = new EnumMap<>(FontFamily.class);

    private TextureAtlas spriteAtlas;
    private Texture darknessOverlay;
    private Texture headlightOverlay;
    private TiledMap map;

    private EntitySprites entitySprites;
    private LightingOverlays overlays;
    private HudIcons hudIcons;

    /**
     * Loads all game-managed assets.
     */
    public AssetLoader() {
        load();
    }

    /**
     * Reloads every asset from disk,
     * disposing whatever was previously loaded.
     */
    public void reload() {
        disposeAssets();
        bakedFonts.clear();
        load();
    }

    /**
     * Returns the loaded entity sprites.
     */
    public EntitySprites entitySprites() {
        return entitySprites;
    }

    /**
     * Returns the loaded overlay textures.
     */
    public LightingOverlays overlays() {
        return overlays;
    }

    /**
     * Returns the loaded HUD control icons.
     */
    public HudIcons hudIcons() {
        return hudIcons;
    }

    /**
     * Returns the loaded Tiled map.
     */
    public TiledMap map() {
        return map;
    }

    /**
     * Bakes a font following {@code spec}.
     *
     * @param spec which family to bake from and how the font should look
     *
     * @return the baked font
     */
    public BakedFont font(FontSpec spec) {
        var bakedFont = new BakedFont(fontGenerators.get(spec.family()), spec);
        bakedFonts.add(bakedFont);
        return bakedFont;
    }

    private void load() {
        spriteAtlas = new TextureAtlas(Gdx.files.internal(ATLAS_PATH));
        darknessOverlay = loadLinear(DARKNESS_OVERLAY_PATH);
        headlightOverlay = loadLinear(HEADLIGHT_OVERLAY_PATH);
        for (var family : FontFamily.values()) {
            var generator = new FreeTypeFontGenerator(Gdx.files.internal(family.path()));
            fontGenerators.put(family, generator);
        }
        map = new TmxMapLoader().load(MAP_PATH);

        entitySprites = new EntitySprites(spriteAtlas);
        overlays = new LightingOverlays(darknessOverlay, headlightOverlay);
        hudIcons = new HudIcons(
                findRegion(spriteAtlas, "arrow-right-active"),
                findRegion(spriteAtlas, "arrow-right-inactive")
        );
    }

    private static Texture loadLinear(String internalPath) {
        var texture = new Texture(Gdx.files.internal(internalPath));
        texture.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
        return texture;
    }

    private static TextureRegion findRegion(TextureAtlas atlas, String name) {
        return Objects.requireNonNull(atlas.findRegion(name), "no atlas region: " + name);
    }

    @Override
    public void dispose() {
        disposeAssets();
    }

    private void disposeAssets() {
        spriteAtlas.dispose();
        darknessOverlay.dispose();
        headlightOverlay.dispose();
        fontGenerators.values().forEach(FreeTypeFontGenerator::dispose);
        bakedFonts.forEach(BakedFont::dispose);
        map.dispose();
    }
}
