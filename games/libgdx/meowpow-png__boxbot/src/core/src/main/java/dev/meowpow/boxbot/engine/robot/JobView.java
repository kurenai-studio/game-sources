package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;

import java.util.Objects;

/**
 * A pending job available for the controller to take.
 *
 * @param jobId the job's identifier
 * @param type the job's type
 * @param shelfId source shelf for retrieval; suggested shelf for putaway
 * @param packageId the package this job concerns
 * @param color the package's color
 */
public record JobView(
        JobId jobId,
        JobType type,
        ShelfId shelfId,
        PackageId packageId,
        PackageColor color
) {

    /**
     * @throws NullPointerException if {@code jobId}, {@code type},
     * {@code shelfId}, {@code packageId}, or {@code color} is null
     */
    public JobView {
        Objects.requireNonNull(jobId, "jobId must not be null");
        Objects.requireNonNull(type, "type must not be null");
        Objects.requireNonNull(shelfId, "shelfId must not be null");
        Objects.requireNonNull(packageId, "packageId must not be null");
        Objects.requireNonNull(color, "color must not be null");
    }
}
