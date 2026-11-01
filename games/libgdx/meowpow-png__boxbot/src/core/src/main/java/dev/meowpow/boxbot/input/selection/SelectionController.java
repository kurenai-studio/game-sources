package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.robot.PlayerCommands;
import dev.meowpow.boxbot.engine.robot.RelocationDestination;
import dev.meowpow.boxbot.engine.robot.RobotAction;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.HotPath;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.math.Vector2;

import java.util.Objects;

/**
 * Turns player clicks into selection
 * changes and the robot commands they imply.
 */
@HotPath
public final class SelectionController {

    private final SelectionHitTester hitTester = new SelectionHitTester();
    private final SelectionState state;
    private final PlayerCommands commands;

    /**
     * Creates a controller issuing commands whose
     * queue holds at most {@code queueLimit} pairs.
     *
     * @throws NullPointerException if {@code commands} is null
     * @throws IllegalArgumentException if {@code queueLimit} is not positive
     */
    public SelectionController(PlayerCommands commands, int queueLimit) {
        Objects.requireNonNull(commands, "commands must not be null");
        this.commands = commands;
        this.state = new SelectionState(queueLimit);
    }

    /**
     * Returns the current primary
     * selection, or null if nothing is selected.
     */
    public @Nullable SelectionTarget primary() {
        return state.primary();
    }

    /**
     * Returns the current secondary
     * selection, or null if nothing is selected.
     */
    public @Nullable SelectionTarget secondary() {
        return state.secondary();
    }

    /**
     * Returns the queued pairs, in
     * the order they'll be dispatched.
     */
    public ArrayView<SelectionPair> queuedPairs() {
        return state.queue().pairs();
    }

    /**
     * Returns the primary of the pair currently being
     * staged for the queue, or null if nothing is staged.
     */
    public @Nullable SelectionTarget stagingPrimary() {
        return state.build().primary();
    }

    /**
     * Returns the secondary of the pair
     * currently being staged for the queue,
     * or null if nothing is staged yet.
     */
    public @Nullable SelectionTarget stagingSecondary() {
        return state.build().secondary();
    }

    /**
     * Handles a left click at the given {@code worldPoint}.
     * <p>
     * A miss is always a no-op. A stray click can
     * never clear an existing selection or queue.
     */
    public void onClick(World world, TileSize tileSize, Vector2 worldPoint) {
        var source = hitTester.hitTest(world, tileSize, worldPoint.x, worldPoint.y);
        if (source != null) {
            onSourceClick(world, source);
            return;
        }
        var destination = hitTester.hitTestDestination(
                world,
                tileSize,
                worldPoint.x,
                worldPoint.y
        );
        if (destination != null) {
            onDestinationClick(world, destination);
        }
    }

    /**
     * Handles a click on the given source selection target.
     */
    private void onSourceClick(World world, SelectionTarget hit) {
        if (hit instanceof SelectionTarget.Station) {
            dispatchStationClick(world, hit);
            return;
        }
        if (hit.equals(state.primary())) {
            state.clearPrimary();
            state.clearSecondary();
            commands.cancelPickup();
            return;
        }
        boolean targetIsPackage = state.primary() instanceof SelectionTarget.WorldPackage;
        if (state.secondary() == null && (targetIsPackage || commands.isRelocating())) {
            return;
        }
        boolean hasPrimary = state.build().primary() != null;
        boolean queueIsEmpty = state.queue().pairs().isEmpty();

        if (commands.isIdle() && !hasPrimary && queueIsEmpty) {
            state.select(hit);
            dispatchPrimaryCommand(hit);
            return;
        }
        if (state.queue().remove(hit)) {
            return;
        }
        state.build().stagePrimary(hit);
    }

    /**
     * Handles a click on the charging station.
     * <p>
     * Always discards an in-progress build and is never
     * queued. Left alone if relocation is pending but not
     * yet picked up, since the command would be ignored anyway.
     */
    private void dispatchStationClick(World world, SelectionTarget hit) {
        state.build().clear();

        boolean isRelocating = commands.isRelocating();
        boolean isCarryingPackage = world.robot().carriedPackage() != null;
        if (isRelocating && !isCarryingPackage) {
            return;
        }
        var previousSecondary = state.secondary();
        state.select(hit);
        if (isRelocating) {
            state.redirectSecondary(previousSecondary);
        }
        var newPrimary = state.primary();
        if (newPrimary == null) {
            return;
        }
        dispatchPrimaryCommand(newPrimary);
    }

    private void dispatchPrimaryCommand(SelectionTarget primary) {
        switch (primary) {
            case SelectionTarget.Station ignored -> commands.commitCharge();
            case SelectionTarget.ShelfPackage(var shelf) -> commands.commitRetrieveFromShelf(shelf.id());
            default -> {}
        }
    }

    /**
     * Handles a click on the given destination selection target.
     */
    private void onDestinationClick(World world, SelectionTarget hit) {
        if (state.build().primary() != null) {
            completeBuildSecondary(world, hit);
            return;
        }
        var primary = state.primary();
        if (primary != null) {
            completeLiveSecondary(world, primary, hit);
            return;
        }
        if (state.queue().removeBySecondary(hit)) {
            return;
        }
        if (commands.isRelocating() && world.robot().action() != RobotAction.DROPPING_OFF) {
            redirectActiveRelocation(world, hit);
        }
    }

    private void completeLiveSecondary(World world, SelectionTarget primary, SelectionTarget hit) {
        if (!primary.canRelocate(world)) {
            return;
        }
        var worldPackage = (SelectionTarget.WorldPackage) primary;
        if (!isBayDeliveryAllowed(world, worldPackage, hit)) {
            return;
        }
        state.selectSecondary(hit);

        var destination = toRelocationDestination(state.secondary());
        if (destination != null) {
            dispatchRelocation(worldPackage, destination);
        }
    }

    private void completeBuildSecondary(World world, SelectionTarget hit) {
        var stagingPrimary = state.build().primary();
        if (stagingPrimary == null || !stagingPrimary.canRelocate(world)) {
            return;
        }
        var worldPackage = (SelectionTarget.WorldPackage) stagingPrimary;
        if (!isBayDeliveryAllowed(world, worldPackage, hit)) {
            return;
        }
        var completed = state.build().stageSecondary(hit);
        if (completed == null) {
            return;
        }
        state.queue().toggle(completed);
        state.build().clear();
    }

    private void redirectActiveRelocation(World world, SelectionTarget hit) {
        if (hit.equals(state.secondary())) {
            commands.cancelDestination();
            state.redirectSecondary(null);
            return;
        }
        if (!isCarriedBayDeliveryAllowed(world, hit)) {
            return;
        }
        var destination = toRelocationDestination(hit);
        if (destination != null) {
            commands.setDestination(destination);
            state.redirectSecondary(hit);
        }
    }

    private boolean isCarriedBayDeliveryAllowed(World world, SelectionTarget destination) {
        if (!(destination instanceof SelectionTarget.BayDestination)) {
            return true;
        }
        var carried = world.robot().carriedPackage();
        return carried != null && hasOpenOrderFor(world, carried.color());
    }

    /**
     * Resumes work once the robot has nothing else in progress.
     * <p>
     * <strong>Implementation Note:</strong>
     * Dispatches the active selection's implied command first,
     * since it was chosen before anything queued after it; only once
     * nothing is actively selected does the next queued pair start.
     *
     * @param world the current world state used to validate queued delivery targets
     */
    public void resumeIfIdle(World world) {
        if (!commands.isIdle()) {
            return;
        }
        var primary = state.primary();
        if (primary != null) {
            var secondary = state.secondary();
            if (secondary != null) {
                dispatchQueuedPair(new SelectionPair(primary, secondary));
            }
            else {
                dispatchPrimaryCommand(primary);
            }
            return;
        }
        SelectionPair next;
        while ((next = state.queue().pollFirst()) != null) {
            if (!isQueuedPairDispatchable(world, next)) {
                continue;
            }
            state.activateQueuedPair(next);
            dispatchQueuedPair(next);
            return;
        }
    }

    private boolean isQueuedPairDispatchable(World world, SelectionPair pair) {
        if (!(pair.primary() instanceof SelectionTarget.WorldPackage worldPackage)) {
            return false;
        }
        return isBayDeliveryAllowed(world, worldPackage, pair.secondary());
    }

    private void dispatchQueuedPair(SelectionPair pair) {
        var primary = pair.primary();
        var destination = toRelocationDestination(pair.secondary());
        if (destination == null || !(primary instanceof SelectionTarget.WorldPackage worldPackage)) {
            return;
        }
        // a shelf source is committed here since a live
        // click already would be; a bay source bundles source and
        // destination in one call, which dispatchRelocation still handles.
        if (worldPackage instanceof SelectionTarget.ShelfPackage(var shelf)) {
            commands.commitRetrieveFromShelf(shelf.id());
        }
        dispatchRelocation(worldPackage, destination);
    }

    /**
     * Clears the primary, secondary, staged, or queued
     * selections that no longer exist in the given world.
     */
    public void pruneStale(World world) {
        var currentPrimary = state.primary();
        if (currentPrimary != null && !isPrimaryStillValid(world, currentPrimary)) {
            state.clearPrimary();
        }
        var currentSecondary = state.secondary();
        if (currentSecondary != null && !isSecondaryStillValid(world, currentSecondary)) {
            state.clearSecondary();
        }
        state.queue().pruneStale(world);
        state.build().pruneStale(world);
    }

    private boolean isPrimaryStillValid(World world, SelectionTarget primary) {
        if (primary instanceof SelectionTarget.Station) {
            return world.robot().action() != RobotAction.CHARGING;
        }
        return primary.isPresent(world);
    }

    private @Nullable RelocationDestination toRelocationDestination(
            @Nullable SelectionTarget target
    ) {
        switch (target) {
            case SelectionTarget.EmptyShelf(var shelf) -> {
                return new RelocationDestination.Shelf(shelf.id());
            }
            case SelectionTarget.BayDestination ignored -> {
                return new RelocationDestination.Bay();
            }
            case null, default -> {
                return null;
            }
        }
    }

    private boolean isSecondaryStillValid(World world, SelectionTarget secondary) {
        if (secondary instanceof SelectionTarget.BayDestination) {
            return commands.isRelocating();
        }
        return secondary.isPresent(world);
    }

    private boolean isBayDeliveryAllowed(
            World world,
            SelectionTarget.WorldPackage source,
            SelectionTarget destination
    ) {
        if (!(destination instanceof SelectionTarget.BayDestination)) {
            return true;
        }
        if (!(source instanceof SelectionTarget.ShelfPackage(var shelf))) {
            return false;
        }
        var pkg = shelf.occupyingPackage();
        return pkg != null && hasOpenOrderFor(world, pkg.color());
    }

    private boolean hasOpenOrderFor(World world, PackageColor color) {
        var orders = world.outboundOrders();
        for (int i = 0; i < orders.size(); i++) {
            if (orders.get(i).color() == color) {
                return true;
            }
        }
        return false;
    }

    private void dispatchRelocation(
            SelectionTarget.WorldPackage source,
            RelocationDestination destination
    ) {
        switch (source) {
            case SelectionTarget.ShelfPackage ignored -> commands.setDestination(destination);
            case SelectionTarget.BayPackage(var placement) -> {
                if (destination instanceof RelocationDestination.Shelf(var shelfId)) {
                    commands.commitRelocateFromBay(placement.pkg().id(), shelfId);
                }
            }
        }
    }
}
