package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;

import com.badlogic.gdx.utils.Array;

public final class RobotFixtures {

    private RobotFixtures() {}

    static RobotView idleRobot(int batteryLevel) {
        return new RobotView(
                new GridPos(0, 0),
                new RobotBattery(batteryLevel, 100),
                null,
                null,
                null
        );
    }

    static RobotView carryingRobot(JobType jobType, int batteryLevel) {
        return new RobotView(
                new GridPos(0, 0),
                new RobotBattery(batteryLevel, 100),
                new PackageId(1),
                PackageColor.RED,
                jobType
        );
    }

    public static RobotJob robotJob(World world, String id, JobType type, Package pkg) {
        return new RobotJob(
                new JobId(id),
                type,
                world.shelves().first().id(),
                pkg,
                world.currentTick()
        );
    }

    static Robot robotAt(int maxBattery) {
        return new Robot(new GridPos(0, 0), maxBattery);
    }

    static Robot robotAt() {
        return robotAt(100);
    }

    static Array<GridPos> routeOf(GridPos... positions) {
        var route = new Array<GridPos>(positions.length);
        route.addAll(positions);
        return route;
    }

    static JobView job(String id, PackageId packageId) {
        return new JobView(
                new JobId(id),
                JobType.PUTAWAY,
                new ShelfId(1),
                packageId,
                PackageColor.RED
        );
    }

    static JobView job(String id) {
        return job(id, new PackageId(1));
    }

    @SafeVarargs
    static <T> ArrayView<T> arrayViewOf(T... values) {
        return GdxCollections.viewOf(new Array<>(values));
    }

    static void driveNorth(Robot robot, int cells) {
        var route = new Array<GridPos>(cells);
        for (int y = 1; y <= cells; y++) {
            route.add(new GridPos(0, y));
        }
        robot.followRoute(route);
        for (int i = 0; i < cells; i++) {
            robot.tickMovement(1);
        }
    }
}
