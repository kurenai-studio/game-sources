package dev.meowpow.boxbot.render.assets;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

/**
 * Owns and provides overlay
 * textures used to render lighting.
 */
@HotPath
public record LightingOverlays(Texture darkness, TextureRegion headlight) {

    /**
     * Wraps the given overlay textures for rendering.
     *
     * @param darkness the darkness overlay texture
     * @param headlight the headlight cutout overlay texture
     */
    public LightingOverlays(Texture darkness, Texture headlight) {
        this(darkness, new TextureRegion(headlight));
    }
}
