package dev.meowpow.boxbot.render.assets;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.g2d.TextureRegion;

import java.util.Objects;

/**
 * The sprite icons used to render HUD controls.
 *
 * @param arrowRightActive the depart-now icon shown while it's clickable
 * @param arrowRightInactive the depart-now icon shown while it's disabled
 */
@HotPath
public record HudIcons(TextureRegion arrowRightActive, TextureRegion arrowRightInactive) {

    /**
     * @throws NullPointerException if any texture region is null
     */
    public HudIcons {
        Objects.requireNonNull(arrowRightActive, "arrowRightActive must not be null");
        Objects.requireNonNull(arrowRightInactive, "arrowRightInactive must not be null");
    }
}
