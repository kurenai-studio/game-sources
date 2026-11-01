package dev.meowpow.boxbot.engine.spatial.grid;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.IntArray;
import com.badlogic.gdx.utils.IntSet;

import java.util.Arrays;
import java.util.Objects;

/**
 * Breadth-first pathfinding over grid's walkable tiles.
 */
@HotPath
public final class Pathfinder {

    private static final int[] NEIGHBOR_X_OFFSETS = {1, -1, 0, 0};
    private static final int[] NEIGHBOR_Y_OFFSETS = {0, 0, 1, -1};

    private final IntArray frontier = new IntArray();
    private int[] visited = new int[0];
    private int[] cameFrom = new int[0];
    private int searchId;

    /**
     * Finds the shortest route to a goal.
     * <p>
     * The supplied output buffer is
     * cleared before the route is written.
     */
    public void findPath(Grid grid, GridPos start, IntSet goals, Array<GridPos> output) {
        Objects.requireNonNull(grid, "grid must not be null");
        Objects.requireNonNull(start, "start must not be null");
        Objects.requireNonNull(goals, "goals must not be null");
        Objects.requireNonNull(output, "output must not be null");

        output.clear();
        if (goals.isEmpty() || !grid.inBounds(start.x(), start.y())) {
            return;
        }
        int tileCount = grid.width() * grid.height();
        ensureCapacity(tileCount);
        int visitId = nextSearchId();
        int startIndex = indexOf(grid, start.x(), start.y());
        if (goals.contains(startIndex)) {
            output.add(start);
            return;
        }
        frontier.clear();
        frontier.add(startIndex);
        visited[startIndex] = visitId;
        cameFrom[startIndex] = -1;

        for (int head = 0; head < frontier.size; head++) {
            int current = frontier.get(head);
            int x = current % grid.width();
            int y = current / grid.width();
            int goal = visitNeighbors(grid, goals, visitId, current, x, y);
            if (goal >= 0) {
                writePath(grid, goal, output);
                return;
            }
        }
    }

    private int visitNeighbors(
            Grid grid,
            IntSet goals,
            int visitId,
            int previous,
            int x,
            int y
    ) {
        for (int i = 0; i < NEIGHBOR_X_OFFSETS.length; i++) {
            int goal = visitNeighbor(
                    grid,
                    goals,
                    visitId,
                    previous,
                    x + NEIGHBOR_X_OFFSETS[i],
                    y + NEIGHBOR_Y_OFFSETS[i]
            );
            if (goal >= 0) {
                return goal;
            }
        }
        return -1;
    }

    private int visitNeighbor(
            Grid grid,
            IntSet goals,
            int visitId,
            int previous,
            int x,
            int y
    ) {
        if (!grid.isWalkable(x, y)) {
            return -1;
        }
        int next = indexOf(grid, x, y);
        if (visited[next] == visitId) {
            return -1;
        }
        visited[next] = visitId;
        cameFrom[next] = previous;
        if (goals.contains(next)) {
            return next;
        }
        frontier.add(next);
        return -1;
    }

    private void writePath(Grid grid, int goal, Array<GridPos> output) {
        for (int current = goal; current >= 0; current = cameFrom[current]) {
            output.add(new GridPos(current % grid.width(), current / grid.width()));
        }
        output.reverse();
    }

    private void ensureCapacity(int tileCount) {
        if (visited.length >= tileCount) {
            return;
        }
        visited = Arrays.copyOf(visited, tileCount);
        cameFrom = Arrays.copyOf(cameFrom, tileCount);
    }

    private int nextSearchId() {
        if (searchId == Integer.MAX_VALUE) {
            Arrays.fill(visited, 0);
            searchId = 1;
            return searchId;
        }
        return ++searchId;
    }

    private static int indexOf(Grid grid, int x, int y) {
        return y * grid.width() + x;
    }
}
