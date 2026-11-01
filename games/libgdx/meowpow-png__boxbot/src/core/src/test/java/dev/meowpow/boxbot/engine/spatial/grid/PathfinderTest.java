package dev.meowpow.boxbot.engine.spatial.grid;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.IntSet;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.spatial.grid.GridFixtures.gridOf;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class PathfinderTest {

    @Nested
    @DisplayName("findPath")
    class FindPathMethodTests {

        @Test
        @DisplayName("Returns the shortest path when the grid is open")
        void should_ReturnShortestPath_when_GridIsOpen() {
            var grid = gridOf(".....");
            var start = new GridPos(0, 0);
            var goal = new GridPos(4, 0);

            var path = findPath(grid, start, goal);

            assertThat(path).containsExactly(
                    new GridPos(0, 0),
                    new GridPos(1, 0),
                    new GridPos(2, 0),
                    new GridPos(3, 0),
                    new GridPos(4, 0)
            );
        }

        @Test
        @DisplayName("Returns a path around an obstacle when the direct route is blocked")
        void should_ReturnPathAroundObstacle_when_DirectRouteIsBlocked() {
            var grid = gridOf(
                    "....",
                    ".##.",
                    "...."
            );
            var start = new GridPos(0, 1);
            var goal = new GridPos(3, 1);

            var path = findPath(grid, start, goal);

            assertThat(path).hasSize(6);
            assertThat(path.first()).isEqualTo(start);
            assertThat(path.peek()).isEqualTo(goal);
            assertThat(path).doesNotContain(
                    new GridPos(1, 1),
                    new GridPos(2, 1)
            );
        }

        @Test
        @DisplayName("Returns an empty path when the goal is unreachable")
        void should_ReturnEmptyPath_when_GoalIsUnreachable() {
            var grid = gridOf("...#..");
            var start = new GridPos(0, 0);
            var goal = new GridPos(5, 0);

            var path = findPath(grid, start, goal);

            assertThat(path).isEmpty();
        }

        @Test
        @DisplayName("Returns the start position when it is already a goal")
        void should_ReturnStartPosition_when_StartIsAlreadyGoal() {
            var grid = gridOf("...");
            var start = new GridPos(1, 0);

            var path = findPath(grid, start, start);

            assertThat(path).containsExactly(start);
        }

        @Test
        @DisplayName("Returns an empty path when there are no goals")
        void should_ReturnEmptyPath_when_GoalSetIsEmpty() {
            var grid = gridOf("...");
            var start = new GridPos(0, 0);

            var path = findPath(grid, start);

            assertThat(path).isEmpty();
        }

        @Test
        @DisplayName("Reaches the nearest goal when multiple goals are reachable")
        void should_ReachNearestGoal_when_MultipleGoalsAreReachable() {
            var grid = gridOf("......");
            var start = new GridPos(0, 0);
            var nearGoal = new GridPos(2, 0);
            var farGoal = new GridPos(5, 0);

            var path = findPath(grid, start, farGoal, nearGoal);

            assertThat(path.peek()).isEqualTo(nearGoal);
        }

        @Test
        @DisplayName("Never reaches a goal cell that is not walkable")
        void should_NeverReachGoal_when_GoalCellIsUnwalkable() {
            var grid = gridOf("...#");
            var start = new GridPos(0, 0);
            var unwalkableGoal = new GridPos(3, 0);

            var path = findPath(grid, start, unwalkableGoal);

            assertThat(path).isEmpty();
        }

        @Test
        @DisplayName("Reaches a tile adjacent to a footprint when goals come from adjacentWalkableTiles")
        void should_ReachAdjacentTile_when_GoalsComeFromFootprint() {
            var grid = gridOf("...");
            var shelf = Footprint.singleTile(new GridPos(2, 0));
            var start = new GridPos(0, 0);

            var path = findPath(grid, start, new GridPos(1, 0));

            assertThat(path.peek()).isEqualTo(new GridPos(1, 0));
            assertThat(path).doesNotContain(shelf.anchor());
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null grid")
        void should_RejectGrid_when_GridIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Pathfinder().findPath(
                    null,
                    new GridPos(0, 0),
                    new IntSet(),
                    new Array<>()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null start position")
        void should_RejectStart_when_StartIsNull() {
            var pathfinder = new Pathfinder();

            assertThatNullPointerException().isThrownBy(() -> pathfinder.findPath(
                    gridOf("."),
                    null,
                    new IntSet(),
                    new Array<>()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null goal set")
        void should_RejectGoals_when_GoalsAreNull() {
            var pathfinder = new Pathfinder();

            assertThatNullPointerException().isThrownBy(() -> pathfinder.findPath(
                    gridOf("."),
                    new GridPos(0, 0),
                    null,
                    new Array<>()
            ));
        }
    }

    @Nested
    @DisplayName("reusable findPath")
    class ReusableFindPathMethodTests {

        @Test
        @DisplayName("Reuses the supplied output buffer for the shortest path")
        void should_ReplaceOutputWithShortestPath_when_BufferIsReused() {
            var grid = gridOf(".....");
            var goals = new IntSet();

            goals.add(4);

            var output = new Array<GridPos>();
            output.add(new GridPos(99, 99));

            var pathfinder = new Pathfinder();
            pathfinder.findPath(grid, new GridPos(0, 0), goals, output);

            assertThat(output).containsExactly(
                    new GridPos(0, 0),
                    new GridPos(1, 0),
                    new GridPos(2, 0),
                    new GridPos(3, 0),
                    new GridPos(4, 0)
            );
        }
    }

    private static Array<GridPos> findPath(Grid grid, GridPos start, GridPos... goals) {
        var goalIndices = new IntSet();
        for (var goal : goals) {
            goalIndices.add(goal.y() * grid.width() + goal.x());
        }
        var output = new Array<GridPos>();
        var pathfinder = new Pathfinder();

        pathfinder.findPath(grid, start, goalIndices, output);
        return output;
    }
}
