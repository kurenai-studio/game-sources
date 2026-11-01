package dev.meowpow.boxbot.engine.spatial.grid;

import com.badlogic.gdx.utils.IntSet;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.spatial.grid.FootprintFixtures.*;
import static dev.meowpow.boxbot.engine.spatial.grid.GridFixtures.gridOf;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class FootprintTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null anchor")
        void should_RejectAnchor_when_AnchorIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Footprint(
                    null,
                    new TileExtent(1, 1)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null extent")
        void should_RejectExtent_when_ExtentIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Footprint(
                    new GridPos(0, 0),
                    null
            ));
        }
    }

    @Nested
    @DisplayName("singleTile")
    class SingleTileMethodTests {

        @Test
        @DisplayName("Creates a one-by-one footprint at the supplied position")
        void should_CreateSingleTileFootprint_when_PositionIsProvided() {
            var position = new GridPos(2, 3);
            var expected = new Footprint(
                    position,
                    new TileExtent(1, 1)
            );
            assertThat(Footprint.singleTile(position)).isEqualTo(expected);
        }
    }

    @Nested
    @DisplayName("tileCount")
    class TileCountMethodTests {

        @Test
        @DisplayName("Returns the number of tiles covered by the footprint")
        void should_ReturnCoveredTileCount_when_FootprintHasArea() {
            var footprint = new Footprint(
                    new GridPos(1, 2),
                    new TileExtent(3, 2)
            );
            assertThat(footprint.tileCount()).isEqualTo(6);
        }

        @Test
        @DisplayName("Returns zero when an extent dimension is zero")
        void should_ReturnZero_when_ExtentDimensionIsZero() {
            var footprint = new Footprint(
                    new GridPos(1, 2),
                    new TileExtent(0, 2)
            );
            assertThat(footprint.tileCount()).isZero();
        }
    }

    @Nested
    @DisplayName("addTiles")
    class AddTilesMethodTests {

        @Test
        @DisplayName("Adds every tile in the footprint")
        void should_AddEveryTile_when_FootprintSpansMultipleTiles() {
            var footprint = new Footprint(
                    new GridPos(1, 2),
                    new TileExtent(2, 2)
            );
            GridPos[] expected = {
                    new GridPos(1, 2),
                    new GridPos(1, 3),
                    new GridPos(2, 2),
                    new GridPos(2, 3)
            };
            assertThat(tilesOf(footprint)).containsExactlyInAnyOrder(expected);
        }

        @Test
        @DisplayName("Adds no tiles when an extent dimension is zero")
        void should_AddNoTiles_when_ExtentDimensionIsZero() {
            var footprint = new Footprint(
                    new GridPos(1, 2),
                    new TileExtent(0, 2)
            );
            assertThat(tilesOf(footprint)).isEmpty();
        }
    }

    @Nested
    @DisplayName("addTileIndices")
    class AddTileIndicesMethodTests {

        @Test
        @DisplayName("Adds every tile index in the footprint")
        void should_AddEveryTileIndex_when_FootprintSpansMultipleTiles() {
            var grid = gridOf(
                    "....",
                    "....",
                    "....",
                    "...."
            );
            var footprint = new Footprint(
                    new GridPos(1, 1),
                    new TileExtent(2, 2)
            );
            GridPos[] expected = {
                    new GridPos(1, 1),
                    new GridPos(1, 2),
                    new GridPos(2, 1),
                    new GridPos(2, 2)
            };
            assertIndices(grid, tileIndicesOf(footprint, grid), expected);
        }

        @Test
        @DisplayName("Excludes covered tiles outside the grid")
        void should_ExcludeOutOfBoundsTiles_when_FootprintCrossesGridBoundary() {
            var grid = gridOf(
                    "...",
                    "...",
                    "..."
            );
            var footprint = new Footprint(
                    new GridPos(-1, -1),
                    new TileExtent(3, 3)
            );
            GridPos[] expected = {
                    new GridPos(0, 0),
                    new GridPos(0, 1),
                    new GridPos(1, 0),
                    new GridPos(1, 1)
            };
            assertIndices(grid, tileIndicesOf(footprint, grid), expected);
        }
    }

    @Nested
    @DisplayName("centerX")
    class CenterXMethodTests {

        @Test
        @DisplayName("Returns the horizontal center in pixels")
        void should_ReturnPixelCenter_when_TileSizeIsProvided() {
            var footprint = new Footprint(
                    new GridPos(1, 3),
                    new TileExtent(3, 2)
            );
            var tileSize = new TileSize(10);
            assertThat(footprint.centerX(tileSize)).isEqualTo(25f);
        }
    }

    @Nested
    @DisplayName("centerY")
    class CenterYMethodTests {

        @Test
        @DisplayName("Returns the vertical center in pixels")
        void should_ReturnPixelCenter_when_TileSizeIsProvided() {
            var footprint = new Footprint(
                    new GridPos(1, 3),
                    new TileExtent(3, 2)
            );
            var tileSize = new TileSize(10);
            assertThat(footprint.centerY(tileSize)).isEqualTo(40f);
        }
    }

    @Nested
    @DisplayName("addAdjacentWalkableTileIndices")
    class AddAdjacentWalkableTileIndicesMethodTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null grid")
        void should_RejectGrid_when_GridIsNull() {
            var footprint = Footprint.singleTile(GridFixtures.origin());

            assertThatNullPointerException().isThrownBy(() ->
                    footprint.addAdjacentWalkableTileIndices(null, new IntSet())
            );
        }

        @Test
        @DisplayName("Adds walkable neighbors of a single-tile footprint")
        void should_AddWalkableNeighbors_when_FootprintIsSingleTile() {
            var grid = gridOf(
                    ".#.",
                    "...",
                    "..."
            );
            var footprint = Footprint.singleTile(
                    new GridPos(1, 1)
            );
            GridPos[] expected = {
                    new GridPos(2, 1),
                    new GridPos(0, 1),
                    new GridPos(1, 2)
            };
            assertIndices(grid, adjacentTileIndicesOf(footprint, grid), expected);
        }

        @Test
        @DisplayName("Adds only the border ring when the footprint spans multiple tiles")
        void should_AddBorderRing_when_FootprintSpansMultipleTiles() {
            var grid = gridOf(
                    "....",
                    "....",
                    "....",
                    "...."
            );
            var footprint = new Footprint(
                    new GridPos(1, 1),
                    new TileExtent(2, 2)
            );
            GridPos[] expected = {
                    new GridPos(1, 0),
                    new GridPos(2, 0),
                    new GridPos(0, 1),
                    new GridPos(3, 1),
                    new GridPos(0, 2),
                    new GridPos(3, 2),
                    new GridPos(1, 3),
                    new GridPos(2, 3)
            };
            assertIndices(grid, adjacentTileIndicesOf(footprint, grid), expected);
        }

        @Test
        @DisplayName("Excludes out-of-bounds neighbors when the footprint is at the grid boundary")
        void should_ExcludeOutOfBoundsNeighbors_when_FootprintIsAtGridBoundary() {
            var grid = gridOf(
                    "...",
                    "...",
                    "..."
            );
            var footprint = Footprint.singleTile(new GridPos(0, 0));
            var indices = adjacentTileIndicesOf(footprint, grid);

            assertIndices(grid, indices, new GridPos(1, 0), new GridPos(0, 1));
        }
    }

    private static void assertIndices(Grid grid, IntSet actual, GridPos... expected) {
        assertThat(actual.size).isEqualTo(expected.length);
        for (var position : expected) {
            var key = position.y() * grid.width() + position.x();
            assertThat(actual.contains(key)).isTrue();
        }
    }
}
