package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.entity.ChargingStation;
import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.entity.Shelf;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.robot.JobId;
import dev.meowpow.boxbot.engine.robot.JobType;
import dev.meowpow.boxbot.engine.robot.Robot;
import dev.meowpow.boxbot.engine.robot.RobotJob;
import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.Grid;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.gdx.GdxCollections;

import com.badlogic.gdx.utils.Array;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

import static dev.meowpow.boxbot.engine.entity.LoadingBayFixtures.loadingBay;
import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;

public final class TestWorldBuilder {

    private int shelfCount;
    private int loadingBayCapacity = 1;
    private int gridWidth = -1;
    private int gridHeight = -1;

    private boolean walkableGrid;

    private GridPos chargingStationPosition = new GridPos(1, 1);
    private List<PackageColor> shelfPackageColors = List.of();

    private final List<Package> incomingPackages = new ArrayList<>();
    private final List<Package> outgoingPackages = new ArrayList<>();
    private final List<Function<World, RobotJob>> jobs = new ArrayList<>();

    private TestWorldBuilder() {}

    public static TestWorldBuilder world() {
        return new TestWorldBuilder();
    }

    public TestWorldBuilder withShelves(int count) {
        shelfCount = count;
        return this;
    }

    public TestWorldBuilder withLoadingBayCapacity(int capacity) {
        loadingBayCapacity = capacity;
        return this;
    }

    public TestWorldBuilder withWalkableGrid(int width, int height) {
        gridWidth = width;
        gridHeight = height;
        walkableGrid = true;
        return this;
    }

    public TestWorldBuilder withChargingStationAt(GridPos position) {
        chargingStationPosition = position;
        return this;
    }

    public TestWorldBuilder withShelfPackage(PackageColor color) {
        return withShelfPackages(List.of(color));
    }

    public TestWorldBuilder withShelfPackages(List<PackageColor> colors) {
        shelfPackageColors = List.copyOf(colors);
        shelfCount = colors.size();
        return this;
    }

    public TestWorldBuilder withIncomingPackage(Package pkg) {
        incomingPackages.add(pkg);
        return this;
    }

    public TestWorldBuilder withOutgoingPackages(int count) {
        for (int i = 0; i < count; i++) {
            outgoingPackages.add(packageWithId(i));
        }
        return this;
    }

    public TestWorldBuilder withJob(String id, JobType type, Package pkg) {
        return withJob(world -> new RobotJob(
                new JobId(id),
                type,
                world.shelves().first().id(),
                pkg,
                world.currentTick()
        ));
    }

    public TestWorldBuilder withJob(Function<World, RobotJob> jobFactory) {
        jobs.add(jobFactory);
        return this;
    }

    public World build() {
        var robot = new Robot(new GridPos(0, 0), 100);
        var loadingBay = loadingBay(loadingBayCapacity);
        var footprint = Footprint.singleTile(chargingStationPosition);
        var chargingStation = new ChargingStation(footprint);
        int width = gridWidth >= 0 ? gridWidth : Math.max(shelfCount + 2, loadingBayCapacity);
        int height = gridHeight >= 0 ? gridHeight : 1;
        var grid = new Grid(width, height);
        if (walkableGrid) {
            for (int x = 0; x < grid.width(); x++) {
                for (int y = 0; y < grid.height(); y++) {
                    grid.setWalkable(x, y, true);
                }
            }
        }
        var shelves = new Array<Shelf>();
        for (int i = 0; i < shelfCount; i++) {
            shelves.add(new Shelf(new ShelfId(i), new GridPos(i, 0), "S" + i));
        }
        var clock = new SimulationClock();
        var world = new World(
                robot,
                GdxCollections.viewOf(shelves),
                loadingBay,
                chargingStation,
                grid,
                clock
        );
        for (int i = 0; i < shelfPackageColors.size(); i++) {
            var pkg = packageWithId(i, shelfPackageColors.get(i));
            world.setShelfPackage(world.shelves().get(i).id(), pkg);
        }
        for (var pkg : incomingPackages) {
            world.loadingBay().tryPlaceIncoming(pkg);
        }
        for (var pkg : outgoingPackages) {
            world.loadingBay().tryPlaceOutgoing(pkg);
        }
        for (var job : jobs) {
            world.addJob(job.apply(world));
        }
        return world;
    }
}
