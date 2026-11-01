package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Snapshot of the robot's state at decision time.
 *
 * @param position the robot's current grid position
 * @param battery the robot's current battery
 * @param carriedPackageId null when the robot is not carrying a package
 * @param carriedColor the carried package's color; null when not carrying
 * @param carriedJobType whether the carried package is
 * for a putaway or retrieval job; null when not carrying
 */
public record RobotView(
        GridPos position,
        RobotBattery battery,
        @Nullable PackageId carriedPackageId,
        @Nullable PackageColor carriedColor,
        @Nullable JobType carriedJobType
) {

    /**
     * @throws NullPointerException if {@code position} or {@code battery} is null
     * @throws IllegalArgumentException if {@code carriedColor} or {@code carriedJobType}
     * is present without {@code carriedPackageId}, or {@code carriedPackageId}
     * is present without {@code carriedColor} or {@code carriedJobType}
     */
    public RobotView {
        Objects.requireNonNull(position, "position must not be null");
        Objects.requireNonNull(battery, "battery must not be null");
        if (carriedPackageId == null && carriedColor != null) {
            var message = "carriedColor must be null when carriedPackageId is absent, got ";
            throw new IllegalArgumentException(message + carriedColor);
        }
        if (carriedPackageId != null && carriedColor == null) {
            var message = "carriedColor must be present when carriedPackageId is present";
            throw new IllegalArgumentException(message);
        }
        if (carriedPackageId == null && carriedJobType != null) {
            var message = "carriedJobType must be null when carriedPackageId is absent, got ";
            throw new IllegalArgumentException(message + carriedJobType);
        }
        if (carriedPackageId != null && carriedJobType == null) {
            var message = "carriedJobType must be present when carriedPackageId is present";
            throw new IllegalArgumentException(message);
        }
    }
}
