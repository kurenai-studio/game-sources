package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.entity.ShelfId;

import java.util.Objects;

/**
 * A putaway or retrieval job, pending or in progress.
 *
 * @param id the job's identifier
 * @param type the job's type
 * @param shelfId source shelf for retrieval; suggested shelf for putaway
 * @param pkg the package this job concerns
 * @param arrivalTick the tick this job was created
 */
public record RobotJob(
        JobId id,
        JobType type,
        ShelfId shelfId,
        Package pkg,
        int arrivalTick
) {

    /**
     * @throws NullPointerException if {@code id}, {@code type}, or {@code pkg} is null
     */
    public RobotJob {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(type, "type must not be null");
        Objects.requireNonNull(pkg, "pkg must not be null");
    }
}
