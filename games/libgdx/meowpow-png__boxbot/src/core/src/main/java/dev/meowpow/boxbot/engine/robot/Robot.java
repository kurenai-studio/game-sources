package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.spatial.grid.Direction;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.utils.Array;

import java.util.Objects;

/**
 * The warehouse's single robot,
 * advanced each tick by the engine.
 */
@HotPath
public final class Robot {

    private final Array<GridPos> route = new Array<>();
    private final RobotBattery battery;

    private int routeIndex;

    private GridPos position, previousPosition;

    private int actionTicksRemaining;
    private double chargeRatePerTick;

    private @Nullable Package carriedPackage;

    private Direction facing, previousFacing;

    private RobotAction action = RobotAction.IDLE;

    private double batteryDrainAccumulator;
    private double batteryChargeAccumulator;

    /**
     * Creates a robot at the given position with a full battery.
     *
     * @param position the robot's starting grid position
     * @param maxBattery the robot's battery capacity when fully charged
     *
     * @throws NullPointerException if {@code position} is null
     */
    public Robot(GridPos position, int maxBattery) {
        Objects.requireNonNull(position, "position must not be null");
        this.battery = RobotBattery.full(maxBattery);
        this.position = position;
        this.facing = Direction.NORTH;
        this.previousFacing = facing;
        this.previousPosition = position;
    }

    /**
     * Returns the robot's current grid position.
     */
    public GridPos position() {
        return position;
    }

    /**
     * Returns the robot's grid position
     * before the most recent movement tick
     */
    public GridPos previousPosition() {
        return previousPosition;
    }

    /**
     * Returns the direction the robot is currently facing.
     */
    public Direction facing() {
        return facing;
    }

    /**
     * Returns the robot's facing before
     * the most recent movement tick
     */
    public Direction previousFacing() {
        return previousFacing;
    }

    /**
     * Places the robot at {@code position} instantly, with no interpolated movement.
     *
     * @param position the robot's new grid position
     *
     * @throws NullPointerException if {@code position} is null
     */
    public void setPosition(GridPos position) {
        Objects.requireNonNull(position, "position must not be null");
        this.position = position;
        this.previousPosition = position;
    }

    /**
     * Replaces the queued route with
     * positions from LibGDX buffer.
     */
    public void followRoute(Array<GridPos> route) {
        followRoute(route, 0);
    }

    /**
     * Replaces the queued route with positions from a LibGDX buffer.
     */
    public void followRoute(Array<GridPos> route, int startIndex) {
        if (startIndex < 0 || startIndex > route.size) {
            throw new IndexOutOfBoundsException("startIndex out of bounds: " + startIndex);
        }
        this.route.clear();
        this.route.addAll(route, startIndex, route.size - startIndex);
        routeIndex = 0;
    }

    /**
     * Returns whether the robot still has route cells left to travel
     */
    public boolean isMoving() {
        return routeIndex < route.size;
    }

    /**
     * Returns the robot's current action.
     */
    public RobotAction action() {
        return action;
    }

    /**
     * Returns whether the robot is mid-pickup, drop-off, or charging
     */
    public boolean isBusy() {
        return action != RobotAction.IDLE;
    }

    /**
     * Returns the package the robot is carrying, or null if empty-handed
     */
    @Nullable
    public Package carriedPackage() {
        return carriedPackage;
    }

    /**
     * Begins carrying the given package.
     *
     * @param pkg the package to carry
     *
     * @throws NullPointerException if {@code pkg} is null
     */
    public void pickUp(Package pkg) {
        Objects.requireNonNull(pkg, "pkg must not be null");
        carriedPackage = pkg;
    }

    /**
     * Releases the carried package.
     */
    public void dropOff() {
        carriedPackage = null;
    }

    /**
     * Starts a pickup action lasting {@code ticks} ticks.
     *
     * @param ticks duration of the pickup, in ticks
     */
    public void beginPickup(int ticks) {
        action = RobotAction.PICKING_UP;
        actionTicksRemaining = ticks;
    }

    /**
     * Starts a drop-off action lasting {@code ticks} ticks.
     *
     * @param ticks duration of the drop-off, in ticks
     */
    public void beginDropoff(int ticks) {
        action = RobotAction.DROPPING_OFF;
        actionTicksRemaining = ticks;
    }

    /**
     * Starts charging, continuing until the battery is full.
     *
     * @param chargeRatePerTick battery restored per tick while charging
     */
    public void beginCharging(double chargeRatePerTick) {
        action = RobotAction.CHARGING;
        this.chargeRatePerTick = chargeRatePerTick;
        this.batteryChargeAccumulator = 0;
    }

    /**
     * Returns the robot's current battery.
     */
    public RobotBattery battery() {
        return battery;
    }

    /**
     * Advances movement by at most one cell
     * for this tick, following the queued route.
     * <p>
     * <strong>API Note:</strong>
     * Turning to face the next cell and stepping into it are
     * separate ticks. A turn costs no battery, only the step itself does.
     * An empty battery halts movement entirely until the robot is charged again.
     *
     * @param drainPerCell battery drained for stepping into one cell
     */
    public void tickMovement(double drainPerCell) {
        previousPosition = position;
        previousFacing = facing;

        if (!isMoving() || battery.isDepleted()) {
            syncMovementAction();
            return;
        }
        var required = Direction.between(position, route.get(routeIndex));
        if (required != facing) {
            facing = required;
            syncMovementAction();
            return;
        }
        position = route.get(routeIndex++);
        if (routeIndex == route.size) {
            route.clear();
            routeIndex = 0;
        }
        batteryDrainAccumulator += drainPerCell;
        var wholeDrain = (int) batteryDrainAccumulator;
        if (wholeDrain > 0) {
            battery.drain(wholeDrain);
            batteryDrainAccumulator -= wholeDrain;
        }
        syncMovementAction();
    }

    private void syncMovementAction() {
        if (action == RobotAction.IDLE || action == RobotAction.MOVING) {
            var next = isMoving() ? RobotAction.MOVING : RobotAction.IDLE;
            if (next != action) {
                GameLog.debugf(LogTag.ROBOT, "action %s -> %s", action, next);
            }
            action = next;
        }
    }

    /**
     * Advances the current timed action by one tick.
     * <p>
     * Pickup and drop-off finish after their fixed duration.
     */
    public void tickAction() {
        if (action != RobotAction.PICKING_UP && action != RobotAction.DROPPING_OFF) {
            return;
        }
        actionTicksRemaining--;
        if (actionTicksRemaining <= 0) {
            action = RobotAction.IDLE;
        }
    }

    /**
     * Advances battery charging by one tick.
     */
    public void tickCharging() {
        if (action != RobotAction.CHARGING) {
            return;
        }
        batteryChargeAccumulator += chargeRatePerTick;
        var wholeCharge = (int) batteryChargeAccumulator;
        if (wholeCharge > 0) {
            battery.charge(wholeCharge);
            batteryChargeAccumulator -= wholeCharge;
        }
        if (battery.isFull()) {
            action = RobotAction.IDLE;
        }
    }
}
