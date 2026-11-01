package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.engine.entity.Shelf;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;
import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.utils.Array;

import java.util.Objects;

/**
 * Builds a cached {@link Observation} snapshot.
 */
@HotPath
final class ObservationFactory {

    private final World world;
    private final int failureLimit;

    private final Array<ShelfView> shelfViews = new Array<>();
    private final ArrayView<ShelfView> shelfView = GdxCollections.viewOf(shelfViews);

    private boolean hasShelfViews;

    private final Array<JobView> jobViews = new Array<>();
    private final ArrayView<JobView> jobView = GdxCollections.viewOf(jobViews);

    private boolean hasJobViews;

    private final Array<OrderView> orderViews = new Array<>();
    private final ArrayView<OrderView> orderView = GdxCollections.viewOf(orderViews);

    private final Observation observation;

    /**
     * Creates a factory for the given world.
     *
     * @param world the simulation state to read
     * @param failureLimit the configured shipment-failure limit reported in observations
     *
     * @throws NullPointerException if {@code world} is null
     */
    ObservationFactory(World world, int failureLimit) {
        this.world = Objects.requireNonNull(world, "world must not be null");
        this.failureLimit = failureLimit;
        this.observation = new Observation(
                robotView(),
                shelfViews(),
                jobViews(),
                orderViews(),
                world.currentTick(),
                failures(),
                loadingBayView()
        );
    }

    /**
     * Returns the observation,
     * refreshed with the world's current state.
     * <p>
     * <strong>API Note:</strong>
     * The same instance is reused and mutated on every call.
     */
    Observation observation() {
        observation.update(
                robotView(),
                shelfViews(),
                jobViews(),
                orderViews(),
                world.currentTick(),
                failures(),
                loadingBayView()
        );
        return observation;
    }

    private LoadingBayView loadingBayView() {
        var loadingBay = world.loadingBay();
        return new LoadingBayView(loadingBay.freeTiles(), loadingBay.totalTiles());
    }

    private RobotView robotView() {
        var robot = world.robot();
        var position = robot.position();

        var carriedPackage = robot.carriedPackage();
        var carriedPackageId = carriedPackage == null ? null : carriedPackage.id();
        var carriedColor = carriedPackage == null ? null : carriedPackage.color();
        var jobType = carriedPackage == null ? null : world.carriedJobType();

        return new RobotView(
                position,
                robot.battery(),
                carriedPackageId,
                carriedColor,
                jobType
        );
    }

    private ArrayView<ShelfView> shelfViews() {
        boolean shelvesChanged = world.consumeShelfChanges();
        if (hasShelfViews && !shelvesChanged) {
            return shelfView;
        }
        var shelves = world.shelves();

        shelfViews.clear();
        shelfViews.ensureCapacity(shelves.size());

        for (int i = 0; i < shelves.size(); i++) {
            shelfViews.add(toShelfView(shelves.get(i)));
        }
        hasShelfViews = true;
        return shelfView;
    }

    private static ShelfView toShelfView(Shelf shelf) {
        var occupyingPackage = shelf.occupyingPackage();
        var isOccupied = occupyingPackage != null;
        var packageId = occupyingPackage == null ? null : occupyingPackage.id();
        var packageColor = occupyingPackage == null ? null : occupyingPackage.color();

        return new ShelfView(
                shelf.id(),
                shelf.position(),
                isOccupied,
                packageId,
                packageColor
        );
    }

    private ArrayView<JobView> jobViews() {
        boolean jobsChanged = world.consumeJobChanges();
        if (hasJobViews && !jobsChanged) {
            return jobView;
        }
        var jobs = world.jobs();

        jobViews.clear();
        jobViews.ensureCapacity(jobs.size());

        for (int i = 0; i < jobs.size(); i++) {
            jobViews.add(toJobView(jobs.get(i)));
        }
        hasJobViews = true;
        return jobView;
    }

    private static JobView toJobView(RobotJob job) {
        return new JobView(job.id(), job.type(), job.shelfId(), job.pkg().id(), job.pkg().color());
    }

    private ArrayView<OrderView> orderViews() {
        var orders = world.outboundOrders();

        orderViews.clear();
        orderViews.ensureCapacity(orders.size());

        for (int i = 0; i < orders.size(); i++) {
            orderViews.add(toOrderView(orders.get(i)));
        }
        return orderView;
    }

    private static OrderView toOrderView(OutboundOrder order) {
        return new OrderView(order.id(), order.color(), order.deadlineTick());
    }

    private Failures failures() {
        return new Failures(world.shipmentFailures(), failureLimit);
    }
}
