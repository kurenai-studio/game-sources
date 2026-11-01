package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;

/**
 * Player-issued commands accepted by a robot controller.
 */
public interface PlayerCommands {

    /**
     * Commits the robot to retrieving
     * the package on {@code sourceShelfId}.
     * <p>
     * <strong>API Note:</strong>
     * Retargets a pending pickup that hasn't retrieved
     * its package yet; otherwise a no-op while a
     * previous command is still in progress.
     *
     * @param sourceShelfId the shelf currently holding the package
     *
     * @throws NullPointerException if {@code sourceShelfId} is null
     */
    void commitRetrieveFromShelf(ShelfId sourceShelfId);

    /**
     * Commits the robot to relocating the
     * package with the given ID from the
     * loading bay to the destination shelf.
     * <p>
     * <strong>API Note:</strong>
     * Retargets a pending pickup that hasn't retrieved
     * its package yet; otherwise a no-op while a
     * previous command is still in progress.
     *
     * @param packageId the bay package to relocate
     * @param destination the shelf to store it on
     *
     * @throws NullPointerException if either argument is null
     */
    void commitRelocateFromBay(PackageId packageId, ShelfId destination);

    /**
     * Commits the robot to charging at the station.
     * <p>
     * <strong>API Note:</strong>
     * Retargets a pending pickup that hasn't retrieved
     * its package yet; otherwise a no-op while a
     * previous command is still in progress.
     */
    void commitCharge();

    /**
     * Redirects the pending relocation
     * operation to the destination.
     * <p>
     * <strong>API Note:</strong>
     * No-op unless a relocation is currently pending.
     *
     * @param destination the destination to deliver to instead
     *
     * @throws NullPointerException if {@code destination} is null
     */
    void setDestination(RelocationDestination destination);

    /**
     * Cancels the pending relocation's destination,
     * so the robot idles in place, still holding its package.
     * <p>
     * <strong>API Note:</strong>
     * No-op unless a relocation process is currently pending.
     */
    void cancelDestination();

    /**
     * Requests that the pending relocation be
     * abandoned before its package is picked up.
     * <p>
     * <strong>API Note:</strong>
     * No-op once the package is already
     * being carried, or if nothing is pending.
     */
    void cancelPickup();

    /**
     * Returns whether package
     * relocation is currently pending.
     */
    boolean isRelocating();

    /**
     * Returns whether the robot has no
     * command in progress and is free to accept one.
     */
    boolean isIdle();
}
