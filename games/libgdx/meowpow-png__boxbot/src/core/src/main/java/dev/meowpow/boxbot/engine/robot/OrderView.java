package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.OrderId;

import java.util.Objects;

/**
 * A view of an open outbound order.
 *
 * @param orderId the order's identifier
 * @param color the color requested
 * @param deadlineTick the tick by which a matching package must ship
 */
public record OrderView(OrderId orderId, PackageColor color, int deadlineTick) {

    /**
     * @throws NullPointerException if {@code orderId} or {@code color} is null
     */
    public OrderView {
        Objects.requireNonNull(orderId, "orderId must not be null");
        Objects.requireNonNull(color, "color must not be null");
    }
}
