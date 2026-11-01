package dev.luchoc.littlespaceship.game.adapter.render;

import com.badlogic.gdx.graphics.g2d.TextureRegion;
import dev.luchoc.littlespaceship.core.port.SpriteId;

/**
 * Resolves a content sprite id to the region that draws it. One texture behind every region is the
 * whole point: {@link WorldRenderer} binds whichever atlas it is handed once per frame, not once per
 * entity, and that only holds if every id in play comes from the same {@link
 * com.badlogic.gdx.graphics.Texture}.
 *
 * <p>Two implementations exist. {@link PackedSpriteAtlas} loads the real atlas from disk — built by
 * {@code docs/design/atlas/build-atlas.js} from {@code docs/design/mockups/src/01-sprites.js} into
 * {@code assets/atlas/sprites.png}/{@code .atlas}, and what the game ships with today. {@link
 * PlaceholderAtlas} draws silhouettes in code and only runs as a fallback, for a checkout that has
 * not generated the atlas or a sprite id neither one covers. {@link PackedSpriteAtlas#load} picks
 * between them by asking whether the packed atlas file exists, so nothing else in the composition
 * root has to know which one is running.
 */
public interface SpriteAtlas {

    /**
     * @param sprite the id the core handed the visitor
     * @return the region to draw, or null if this atlas does not cover it
     */
    TextureRegion region(SpriteId sprite);

    void dispose();
}
