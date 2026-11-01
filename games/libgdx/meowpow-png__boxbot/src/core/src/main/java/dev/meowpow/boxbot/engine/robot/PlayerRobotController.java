package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Decides the robot's next
 * action from player-issued commands.
 */
@HotPath
public final class PlayerRobotController implements RobotController, PlayerCommands {

    private @Nullable RobotCommand pending;

    private RobotCommand.@Nullable Relocating getRelocation() {
        return pending instanceof RobotCommand.Relocating relocating ? relocating : null;
    }

    @Override
    public void commitRetrieveFromShelf(ShelfId sourceShelfId) {
        var relocateSource = new JobSource.Shelf(sourceShelfId);
        commit(new RobotCommand.Relocating(relocateSource, null, false));
    }

    @Override
    public void commitRelocateFromBay(PackageId packageId, ShelfId destination) {
        var relocateDestination = new RelocationDestination.Shelf(destination);
        var source = new JobSource.Bay(packageId);
        commit(new RobotCommand.Relocating(source, relocateDestination, false));
    }

    @Override
    public void commitCharge() {
        var relocation = getRelocation();
        if (relocation != null) {
            if (relocation.retrieved()) {
                pending = relocation.withChargingRequested(true);
            }
            else {
                var message = "Ignoring charge command, package not yet picked up";
                GameLog.debug(LogTag.ROBOT, message);
            }
            return;
        }
        commit(new RobotCommand.Charging());
    }

    @Override
    public void setDestination(RelocationDestination destination) {
        Objects.requireNonNull(destination, "destination must not be null");
        var relocation = getRelocation();
        if (relocation != null) {
            pending = relocation.withDestination(destination);
        }
    }

    @Override
    public void cancelDestination() {
        var relocation = getRelocation();
        if (relocation != null) {
            pending = relocation.withDestination(null);
        }
    }

    @Override
    public void cancelPickup() {
        var relocation = getRelocation();
        if (relocation != null && !relocation.retrieved()) {
            pending = relocation.withPickupCancelRequested();
        }
    }

    @Override
    public boolean isRelocating() {
        return getRelocation() != null;
    }

    @Override
    public boolean isIdle() {
        return pending == null;
    }

    @Override
    public @Nullable RelocationDestination requestedRedirect() {
        var relocation = getRelocation();
        return relocation != null ? relocation.destination() : null;
    }

    @Override
    public @Nullable RelocationDestination requestedRedirect(Observation observation) {
        var relocation = getRelocation();
        if (relocation == null) {
            return null;
        }
        var destination = relocation.destination();
        return resolvedDeliveryDestination(observation, destination);
    }

    @Override
    public boolean cancelRequested() {
        var relocation = getRelocation();
        return relocation != null && relocation.destination() == null;
    }

    @Override
    public boolean cancelRequested(Observation observation) {
        var relocation = getRelocation();
        if (relocation != null) {
            var destination = relocation.destination();
            return resolvedDeliveryDestination(observation, destination) == null;
        }
        return false;
    }

    @Override
    public boolean pickupCancelled() {
        var relocation = getRelocation();
        return relocation != null && relocation.pickupCancelRequested();
    }

    @Override
    public @Nullable JobSource requestedSource() {
        var relocation = getRelocation();
        return relocation != null && !relocation.retrieved() ? relocation.source() : null;
    }

    @Override
    public boolean chargingRequested() {
        var relocation = getRelocation();
        return relocation != null && relocation.chargingRequested();
    }

    private void commit(RobotCommand command) {
        if (pending != null && !isRetargetable(pending)) {
            var message = "Ignoring command, previous one still in progress";
            GameLog.debug(LogTag.ROBOT, message);
            return;
        }
        pending = command;
    }

    private static boolean isRetargetable(RobotCommand pending) {
        return pending instanceof RobotCommand.Relocating relocating && !relocating.retrieved();
    }

    @Override
    public ControllerDecision decide(Observation observation) {
        return switch (pending) {
            case null -> ControllerDecision.IDLE;
            case RobotCommand.Relocating relocating -> decideRelocating(observation, relocating);
            case RobotCommand.Charging ignored -> decideCharging(observation);
        };
    }

    private ControllerDecision decideRelocating(
            Observation observation,
            RobotCommand.Relocating relocating
    ) {
        if (observation.robot().carriedPackageId() != null) {
            relocating = relocating.withRetrieved();
            pending = relocating;
            if (relocating.chargingRequested()) {
                return decideChargingWhileCarrying(observation, relocating);
            }
            return deliver(observation, relocating.destination());
        }
        if (relocating.retrieved()) {
            pending = null;
            return ControllerDecision.IDLE;
        }
        if (relocating.pickupCancelRequested()) {
            pending = null;
            return ControllerDecision.IDLE;
        }
        return acquire(observation, relocating.source());
    }

    private ControllerDecision decideChargingWhileCarrying(
            Observation observation,
            RobotCommand.Relocating relocating
    ) {
        if (observation.robot().battery().isFull()) {
            pending = relocating.withChargingRequested(false);
            return deliver(observation, relocating.destination());
        }
        return ControllerDecision.CHARGE;
    }

    private ControllerDecision deliver(
            Observation observation,
            @Nullable RelocationDestination destination
    ) {
        return switch (resolvedDeliveryDestination(observation, destination)) {
            case null -> ControllerDecision.IDLE;
            case RelocationDestination.Bay ignored -> ControllerDecision.GO_TO_BAY;
            case RelocationDestination.Shelf(var shelfId) -> new ControllerDecision.StoreAt(shelfId);
        };
    }

    private @Nullable RelocationDestination resolvedDeliveryDestination(
            Observation observation,
            @Nullable RelocationDestination destination
    ) {
        if (!(destination instanceof RelocationDestination.Bay)) {
            return destination;
        }
        if (hasOpenOrderForCarriedPackage(observation)) {
            return destination;
        }
        var shelf = AiRobotController.nearestEmptyShelf(observation);
        return shelf == null ? null : new RelocationDestination.Shelf(shelf.shelfId());
    }

    private boolean hasOpenOrderForCarriedPackage(Observation observation) {
        PackageColor carriedColor = observation.robot().carriedColor();
        if (carriedColor == null) {
            return false;
        }
        var orders = observation.orders();
        for (int i = 0; i < orders.size(); i++) {
            if (orders.get(i).color() == carriedColor) {
                return true;
            }
        }
        return false;
    }

    private ControllerDecision acquire(Observation observation, JobSource source) {
        return switch (source) {
            case JobSource.Shelf(var shelfId) -> new ControllerDecision.Retrieve(shelfId);
            case JobSource.Bay(var packageId) -> takeJob(observation, packageId);
        };
    }

    private ControllerDecision takeJob(Observation observation, PackageId packageId) {
        var jobs = observation.jobs();
        for (int i = 0; i < jobs.size(); i++) {
            var job = jobs.get(i);
            if (job.packageId().equals(packageId)) {
                return new ControllerDecision.TakeJob(job.jobId());
            }
        }
        GameLog.warnf(LogTag.ROBOT,
                "No pending job found for bay package %s",
                packageId
        );
        pending = null;
        return ControllerDecision.IDLE;
    }

    private ControllerDecision decideCharging(Observation observation) {
        if (observation.robot().battery().isFull()) {
            pending = null;
            return ControllerDecision.IDLE;
        }
        return ControllerDecision.CHARGE;
    }
}
