package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.spatial.grid.Footprint;
import dev.meowpow.boxbot.engine.spatial.grid.Grid;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.Pathfinder;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.IntSet;

import java.util.Objects;

/**
 * Plans and drives the robot's
 * route to a target footprint or position.
 */
@HotPath
final class RobotRouter {

    private final World world;

    private final Pathfinder pathfinder = new Pathfinder();
    private final IntSet routeGoals = new IntSet();
    private final Array<GridPos> route = new Array<>();

    /**
     * Creates a router for the given world.
     *
     * @param world the simulation state to read and route within
     *
     * @throws NullPointerException if {@code world} is null
     */
    RobotRouter(World world) {
        this.world = Objects.requireNonNull(world, "world must not be null");
    }

    /**
     * Routes the robot onto
     * any tile of the given footprint.
     */
    void routeToTiles(Footprint footprint) {
        routeGoals.clear();
        footprint.addTileIndices(world.grid(), routeGoals);
        routeToGoals();
    }

    /**
     * Routes the robot to a walkable
     * tile adjacent to the given footprint.
     */
    void routeToAdjacentTiles(Footprint footprint) {
        routeGoals.clear();
        footprint.addAdjacentWalkableTileIndices(world.grid(), routeGoals);
        routeToGoals();
    }

    /**
     * Routes the robot to a walkable
     * tile adjacent to the given position.
     */
    void routeToAdjacentPosition(GridPos position) {
        routeGoals.clear();
        var grid = world.grid();
        addWalkableGoal(grid, position.x() + 1, position.y());
        addWalkableGoal(grid, position.x() - 1, position.y());
        addWalkableGoal(grid, position.x(), position.y() + 1);
        addWalkableGoal(grid, position.x(), position.y() - 1);
        routeToGoals();
    }

    /**
     * Clears any route in progress,
     * halting the robot in place.
     */
    void stop() {
        route.clear();
        world.robot().followRoute(route);
    }

    private void addWalkableGoal(Grid grid, int x, int y) {
        if (grid.isWalkable(x, y)) {
            routeGoals.add(y * grid.width() + x);
        }
    }

    private void routeToGoals() {
        var robot = world.robot();
        pathfinder.findPath(world.grid(), robot.position(), routeGoals, route);

        if (route.size > 1) {
            robot.followRoute(route, 1);
        }
        else {
            GameLog.warnf(LogTag.ROUTE,
                    "No path found to goal(s) from %s",
                    robot.position()
            );
        }
    }
}
