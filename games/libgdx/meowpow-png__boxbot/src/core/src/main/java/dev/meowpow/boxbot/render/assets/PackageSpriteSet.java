package dev.meowpow.boxbot.render.assets;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.g2d.TextureAtlas;

import java.util.Objects;

/**
 * Package sprites for every real color,
 * loaded from a shared atlas region name prefix.
 */
@HotPath
final class PackageSpriteSet {

    private static final float SIZE_RATIO = 0.3f;

    private final EntitySprite[] sprites = new EntitySprite[PackageColor.values().length];

    private PackageSpriteSet() {}

    /**
     * Loads a sprite for every real color
     * from the {@code <namePrefix>-<color>} atlas region.
     *
     * @param atlas the atlas to load regions from
     * @param namePrefix the shared atlas region name prefix
     */
    static PackageSpriteSet load(TextureAtlas atlas, String namePrefix) {
        var set = new PackageSpriteSet();
        var colors = PackageColor.colored();

        for (int i = 0; i < colors.size; i++) {
            var color = colors.get(i);
            set.sprites[color.ordinal()] = set.loadSprite(
                    atlas,
                    namePrefix,
                    color.name().toLowerCase()
            );
        }
        return set;
    }

    /**
     * Returns the sprite for the given color.
     */
    EntitySprite get(PackageColor color) {
        return Objects.requireNonNull(sprites[color.ordinal()]);
    }

    private EntitySprite loadSprite(TextureAtlas atlas, String namePrefix, String suffix) {
        return EntitySprites.atlasSprite(
                atlas,
                namePrefix + "-" + suffix,
                SIZE_RATIO
        );
    }
}
