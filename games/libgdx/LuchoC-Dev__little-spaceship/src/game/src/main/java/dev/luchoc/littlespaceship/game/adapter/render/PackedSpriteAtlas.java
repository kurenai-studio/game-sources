package dev.luchoc.littlespaceship.game.adapter.render;

import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import dev.luchoc.littlespaceship.core.port.SpriteId;

/**
 * The real atlas: a {@code .atlas}/{@code .png} pair produced by libGDX's own {@code TexturePacker},
 * loaded through {@link TextureAtlas} — a plain-text pack file and no reflection, so it costs
 * nothing extra under TeaVM per {@code CLAUDE.md}'s "prefer boring APIs".
 *
 * <p>This is the seam the art lane's pixels cross into the running game. Nothing in {@code
 * WorldRenderer} or the composition root changes when the atlas is regenerated: {@code
 * docs/design/atlas/build-atlas.js} rasterises {@code docs/design/mockups/src/01-sprites.js} — the
 * one place the pixel art is authored — into {@code assets/atlas/sprites.png}/{@code .atlas}, and
 * {@link #load} finds it there. A Gradle task that ran the generator automatically was considered
 * and rejected for now: the script is Node, this build is Gradle/Java, and wiring the two costs more
 * than running {@code node docs/design/atlas/build-atlas.js} by hand the rare times the art changes.
 * {@link PlaceholderAtlas} remains as the fallback in {@link #load} for a checkout that has not run
 * the generator, or for any sprite id it does not (yet) cover.
 */
public final class PackedSpriteAtlas implements SpriteAtlas {

    /** Where a packed atlas is expected, relative to the assets root both launchers agree on. */
    static final String ATLAS_PATH = "atlas/sprites.atlas";

    private final TextureAtlas atlas;

    private PackedSpriteAtlas(TextureAtlas atlas) {
        this.atlas = atlas;
    }

    /**
     * @param assetsRoot the assets root, e.g. {@code Gdx.files.internal("")}
     * @return a real atlas if {@link #ATLAS_PATH} exists under it, or a generated placeholder set
     *     otherwise
     */
    public static SpriteAtlas load(FileHandle assetsRoot) {
        FileHandle packed = assetsRoot.child(ATLAS_PATH);
        if (packed.exists()) {
            return new PackedSpriteAtlas(new TextureAtlas(packed));
        }
        return new PlaceholderAtlas();
    }

    @Override
    public TextureRegion region(SpriteId sprite) {
        return atlas.findRegion(sprite.value());
    }

    @Override
    public void dispose() {
        atlas.dispose();
    }
}
