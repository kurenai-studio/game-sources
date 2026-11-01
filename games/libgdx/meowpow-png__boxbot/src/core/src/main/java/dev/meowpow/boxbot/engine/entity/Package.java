package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.gdx.HotPath;

import java.util.Objects;

/**
 * A physical package, distinguished only by its color.
 *
 * @param id the package's identifier
 * @param color the package's color
 */
@HotPath
public record Package(PackageId id, PackageColor color) {

    /**
     * @throws NullPointerException if {@code id} or {@code color} is null
     */
    public Package {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(color, "color must not be null");
    }
}
