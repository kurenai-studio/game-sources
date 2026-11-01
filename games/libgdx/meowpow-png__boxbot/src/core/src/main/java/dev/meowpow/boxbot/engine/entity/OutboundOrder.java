package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.gdx.HotPath;

import java.util.Objects;

/**
 * A delivery timer racing to ship a package
 * of the requested color before it expires.
 *
 * @param id the order's identifier
 * @param color the package color this order requests
 * @param deadlineTick the tick by which a matching package must ship
 */
@HotPath
public record OutboundOrder(OrderId id, PackageColor color, int deadlineTick) {

    /**
     * @throws NullPointerException if {@code id} or {@code color} is null
     * @throws IllegalArgumentException if {@code deadlineTick}
     * is negative, or {@code color} is {@link PackageColor#NONE}
     */
    public OutboundOrder {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(color, "color must not be null");
        if (color == PackageColor.NONE) {
            throw new IllegalArgumentException("color must not be NONE");
        }
        if (deadlineTick < 0) {
            var message = "deadlineTick must be >= 0, got " + deadlineTick;
            throw new IllegalArgumentException(message);
        }
    }
}
