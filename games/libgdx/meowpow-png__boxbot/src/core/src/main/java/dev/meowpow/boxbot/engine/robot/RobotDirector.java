package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Translates controller's decisions into actions.
 */
@HotPath
public final class RobotDirector {

    private static final int PICKUP_TICKS = 3;
    private static final int DROPOFF_TICKS = 3;

    private static final double BATTERY_DRAIN_PER_CELL = 0.5;
    private static final double BATTERY_CHARGE_PER_TICK = 1.5;

    private final World world;
    private final RobotController controller;
    private final ObservationFactory observationFactory;
    private final RobotRouter router;

    private @Nullable RobotPhase phase;
    private @Nullable RobotJob activeJob;

    /**
     * Creates a director for the given world and controller.
     *
     * @param world the simulation state to read and mutate
     * @param controller the controller consulted for decisions
     * @param failureLimit the configured shipment-failure limit reported to the controller
     *
     * @throws NullPointerException if {@code world} or {@code controller} is null
     * @throws IllegalArgumentException if {@code failureLimit} is negative
     */
    public RobotDirector(World world, RobotController controller, int failureLimit) {
        Objects.requireNonNull(world, "world must not be null");
        Objects.requireNonNull(controller, "controller must not be null");
        if (failureLimit < 0) {
            throw new IllegalArgumentException("failureLimit must be >= 0, got " + failureLimit);
        }
        this.world = world;
        this.controller = controller;
        this.observationFactory = new ObservationFactory(world, failureLimit);
        this.router = new RobotRouter(world);
    }

    /**
     * Advances robot movement by one tick.
     */
    public void tickMovement() {
        checkForRedirect();
        checkForChargeDetour();
        checkForSourceRedirect();
        checkForSourceCancel();
        world.robot().tickMovement(BATTERY_DRAIN_PER_CELL);
        advanceIfReady();
    }

    /**
     * Advances the robot's current timed action by one tick.
     */
    public void tickAction() {
        world.robot().tickAction();
        advanceIfReady();
    }

    /**
     * Advances battery charging by one tick.
     */
    public void tickCharging() {
        world.robot().tickCharging();
        advanceIfReady();
    }

    /**
     * Re-consults the controller immediately if the robot
     * is idle, instead of waiting for the next tick to
     * notice a command that just became available.
     */
    public void wakeIfIdle() {
        var robot = world.robot();
        if (phase == null && !robot.isMoving() && !robot.isBusy()) {
            decide();
        }
    }

    private void advanceIfReady() {
        var robot = world.robot();
        if (robot.isMoving() || robot.isBusy()) {
            return;
        }
        switch (phase) {
            case null -> decide();
            case RobotPhase.ToSource ignored -> beginPickup();
            case RobotPhase.PickingUp ignored -> afterPickup();
            case RobotPhase.ToDestination(var destination) -> beginDropoff(destination);
            case RobotPhase.DroppingOff(var destination) -> completeJob(destination);
            case RobotPhase.ToChargingStation ignored -> beginCharging();
            case RobotPhase.Charging ignored -> completeCharging();
            case RobotPhase.Stopped ignored -> {}
        }
    }

    private void decide() {
        var action = controller.decide(observationFactory.observation());
        if (!(action instanceof ControllerDecision.Idle)) {
            GameLog.debugf(LogTag.ROBOT, "Decided %s", action);
        }
        switch (action) {
            case ControllerDecision.TakeJob(JobId jobId) -> takeJob(jobId);
            case ControllerDecision.Retrieve(ShelfId shelfId) -> retrieve(shelfId);
            case ControllerDecision.StoreAt(ShelfId shelfId) -> storeAt(shelfId);
            case ControllerDecision.Charge ignored -> charge();
            case ControllerDecision.GoToBay ignored -> goToBay();
            default -> {}
        }
    }

    /**
     * Re-consults the controller while en
     * route to a delivery, and reroutes if
     * it now wants a different shelf.
     */
    private void checkForRedirect() {
        if (activeJob == null) {
            return;
        }
        RelocationDestination current;
        if (phase instanceof RobotPhase.ToDestination(var destination)) {
            current = destination;
        }
        else if (phase instanceof RobotPhase.Stopped) {
            current = null;
        }
        else {
            return;
        }
        var observation = observationFactory.observation();
        if (controller.cancelRequested(observation)) {
            abandonDelivery();
            return;
        }
        var requested = controller.requestedRedirect(observation);
        if (requested != null && !requested.equals(current)) {
            redirectTo(requested);
        }
    }

    /**
     * Detours to the charging station mid-delivery,
     * carrying the currently held package along, if requested.
     */
    private void checkForChargeDetour() {
        if (!(phase instanceof RobotPhase.ToDestination) || activeJob == null) {
            return;
        }
        if (!controller.chargingRequested()) {
            return;
        }
        if (world.robot().carriedPackage() == null) {
            var message = "Skip charge detour. Robot isn't carrying a package";
            GameLog.warn(LogTag.ROBOT, message);
            return;
        }
        router.stop();
        phase = RobotPhase.TO_CHARGING_STATION;

        var footprint = world.chargingStation().footprint();
        router.routeToTiles(footprint);
    }

    /**
     * Abandons an in-progress trip to a job's
     * source before its package has been picked up.
     */
    private void checkForSourceCancel() {
        if (!(phase instanceof RobotPhase.ToSource) || activeJob == null) {
            return;
        }
        if (!controller.pickupCancelled()) {
            return;
        }
        abandonSource(activeJob);
        router.stop();
        activeJob = null;
        phase = null;
    }

    private void checkForSourceRedirect() {
        if (!(phase instanceof RobotPhase.ToSource) || activeJob == null) {
            return;
        }
        if (controller.pickupCancelled()) {
            return;
        }
        var requested = controller.requestedSource();
        if (matchesSource(activeJob, requested)) {
            return;
        }
        abandonSource(activeJob);
        activeJob = null;
        phase = null;
        decide();
    }

    private boolean matchesSource(RobotJob job, @Nullable JobSource requested) {
        boolean isRetrieval = job.type() == JobType.RETRIEVAL;
        return switch (requested) {
            case null -> false;
            case JobSource.Shelf(var shelfId) -> isRetrieval && job.shelfId().equals(shelfId);
            case JobSource.Bay(var packageId) -> isRetrieval && job.pkg().id().equals(packageId);
        };
    }

    private void abandonSource(RobotJob job) {
        if (job.type() == JobType.RETRIEVAL) {
            world.releaseShelf(job.shelfId());
        }
        else {
            world.addJob(job);
        }
    }

    /**
     * Abandons the in-progress delivery,
     * leaving the robot idle in place with
     * its package until a new destination is chosen.
     */
    private void abandonDelivery() {
        router.stop();
        phase = null;
    }

    private void redirectTo(RelocationDestination newDestination) {
        switch (newDestination) {
            case RelocationDestination.Shelf(var shelfId) -> redirectToShelf(shelfId);
            case RelocationDestination.Bay ignored -> redirectToBay();
        }
    }

    private void redirectToShelf(ShelfId shelfId) {
        var shelf = world.shelfById(shelfId);
        if (shelf.occupyingPackage() != null) {
            GameLog.debugf(LogTag.ROBOT,
                    "Redirect target %s is occupied, stopping",
                    shelfId
            );
            stopRobot();
            return;
        }
        var destination = new RelocationDestination.Shelf(shelfId);
        phase = new RobotPhase.ToDestination(destination);

        router.routeToAdjacentPosition(shelf.position());
    }

    private void redirectToBay() {
        if (world.loadingBay().freeTiles() <= 0) {
            GameLog.debug(LogTag.ROBOT,
                    "Redirect loading bay is full, stopping"
            );
            stopRobot();
            return;
        }
        var destination = new RelocationDestination.Bay();
        phase = new RobotPhase.ToDestination(destination);

        router.routeToAdjacentTiles(world.loadingBay().footprint());
    }

    /**
     * Halts the robot in place, unable to reach the
     * requested destination, until a new redirect arrives.
     */
    private void stopRobot() {
        router.stop();
        phase = RobotPhase.STOPPED;
    }

    private void charge() {
        if (activeJob != null && world.robot().carriedPackage() == null) {
            var message = "Skip charging. Robot already has an active job";
            GameLog.debug(LogTag.ROBOT, message);
            return;
        }
        phase = RobotPhase.TO_CHARGING_STATION;
        var footprint = world.chargingStation().footprint();
        router.routeToTiles(footprint);
    }

    private void goToBay() {
        if (activeJob == null || activeJob.type() != JobType.RETRIEVAL || phase != null) {
            var message = "Robot isn't eligible to head to the bay right now";
            GameLog.debug(LogTag.ROBOT, message);
            return;
        }
        if (world.loadingBay().freeTiles() <= 0) {
            GameLog.debug(LogTag.ROBOT, "Loading bay is full");
            return;
        }
        var destination = new RelocationDestination.Bay();
        phase = new RobotPhase.ToDestination(destination);

        var footprint = world.loadingBay().footprint();
        router.routeToAdjacentTiles(footprint);
    }

    private void takeJob(JobId jobId) {
        if (activeJob != null) {
            return;
        }
        RobotJob job = null;
        var jobs = world.jobs();
        for (int i = 0; i < jobs.size(); i++) {
            var candidate = jobs.get(i);
            if (candidate.id().equals(jobId)) {
                job = candidate;
                break;
            }
        }
        if (job == null) {
            GameLog.warnf(LogTag.ROBOT,
                    "Controller requested unknown job %s",
                    jobId
            );
            return;
        }
        world.removeJob(job);
        activeJob = job;
        phase = RobotPhase.TO_SOURCE;

        var footprint = world.loadingBay().footprint();
        router.routeToAdjacentTiles(footprint);
    }

    private void retrieve(ShelfId shelfId) {
        if (activeJob != null) {
            return;
        }
        var shelf = world.shelfById(shelfId);
        var pkg = shelf.occupyingPackage();
        if (pkg == null) {
            GameLog.warnf(LogTag.ROBOT,
                    "Controller requested retrieve on empty shelf %s",
                    shelfId
            );
            return;
        }
        activeJob = new RobotJob(
                retrievalJobId(shelfId),
                JobType.RETRIEVAL,
                shelfId,
                pkg,
                world.currentTick()
        );
        phase = RobotPhase.TO_SOURCE;
        world.reserveShelf(shelfId);

        router.routeToAdjacentPosition(shelf.position());
    }

    private JobId retrievalJobId(ShelfId shelfId) {
        return new JobId("retrieval-" + shelfId);
    }

    private void storeAt(ShelfId shelfId) {
        if (activeJob == null || phase != null) {
            var message = "Robot isn't eligible to route to a shelf right now";
            GameLog.debug(LogTag.ROBOT, message);
            return;
        }
        var destination = new RelocationDestination.Shelf(shelfId);
        phase = new RobotPhase.ToDestination(destination);

        router.routeToAdjacentPosition(world.shelfById(shelfId).position());
    }

    private void beginPickup() {
        world.robot().beginPickup(PICKUP_TICKS);
        phase = RobotPhase.PICKING_UP;
    }

    private void afterPickup() {
        var job = activeJob;
        if (job == null) {
            throw new IllegalStateException("activeJob must be set while picking up");
        }
        if (job.type() == JobType.RETRIEVAL) {
            world.setShelfPackage(job.shelfId(), null);
            world.releaseShelf(job.shelfId());
        }
        else {
            world.loadingBay().remove(job.pkg());
        }
        world.robot().pickUp(job.pkg());
        world.setCarriedJobType(job.type());

        phase = null;
        decide();
    }

    private void beginDropoff(RelocationDestination destination) {
        world.robot().beginDropoff(DROPOFF_TICKS);
        phase = new RobotPhase.DroppingOff(destination);
    }

    private void completeJob(RelocationDestination destination) {
        if (activeJob == null) {
            var message = "activeJob must be set while dropping off";
            throw new IllegalStateException(message);
        }
        var pkg = world.robot().carriedPackage();
        if (pkg == null) {
            var message = "robot must carry a package while dropping off";
            throw new IllegalStateException(message);
        }
        switch (destination) {
            case RelocationDestination.Shelf(var shelfId) -> world.setShelfPackage(shelfId, pkg);
            case RelocationDestination.Bay ignored -> {
                if (!world.loadingBay().tryPlaceOutgoing(pkg)) {
                    var message = "Bay tile unavailable for package " + pkg.id();
                    throw new IllegalStateException(message);
                }
            }
        }
        world.robot().dropOff();
        world.setCarriedJobType(null);
        activeJob = null;
        phase = null;
        decide();
    }

    private void beginCharging() {
        world.robot().beginCharging(BATTERY_CHARGE_PER_TICK);
        phase = RobotPhase.CHARGING;
    }

    private void completeCharging() {
        phase = null;
        decide();
    }
}
