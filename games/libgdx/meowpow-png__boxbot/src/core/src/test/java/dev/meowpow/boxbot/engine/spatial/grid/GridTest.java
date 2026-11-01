package dev.meowpow.boxbot.engine.spatial.grid;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class GridTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains non-negative dimensions")
        void should_RetainDimensions_when_DimensionsAreNonNegative() {
            var grid = new Grid(2, 3);

            assertThat(grid.width()).isEqualTo(2);
            assertThat(grid.height()).isEqualTo(3);
        }

        @Test
        @DisplayName("Initializes every tile as unwalkable")
        void should_InitializeTilesAsUnwalkable_when_Created() {
            var grid = new Grid(2, 2);

            assertThat(grid.isWalkable(0, 0)).isFalse();
            assertThat(grid.isWalkable(1, 0)).isFalse();
            assertThat(grid.isWalkable(0, 1)).isFalse();
            assertThat(grid.isWalkable(1, 1)).isFalse();
        }

        @Test
        @DisplayName("Rejects a negative dimension")
        void should_RejectDimensions_when_WidthOrHeightIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Grid(-1, 0)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Grid(0, -1)
            );
        }
    }

    @Nested
    @DisplayName("inBounds")
    class InBoundsMethodTests {

        @Test
        @DisplayName("Returns true for an in-bounds coordinate")
        void should_ReturnTrue_when_CoordinateIsInBounds() {
            var grid = new Grid(2, 3);

            assertThat(grid.inBounds(1, 2)).isTrue();
        }

        @Test
        @DisplayName("Returns false for an out-of-bounds coordinate")
        void should_ReturnFalse_when_CoordinateIsOutOfBounds() {
            var grid = new Grid(2, 3);

            assertThat(grid.inBounds(-1, 0)).isFalse();
            assertThat(grid.inBounds(2, 0)).isFalse();
            assertThat(grid.inBounds(0, -1)).isFalse();
            assertThat(grid.inBounds(0, 3)).isFalse();
        }
    }

    @Nested
    @DisplayName("isWalkable")
    class IsWalkableMethodTests {

        @Test
        @DisplayName("Returns false for an out-of-bounds coordinate")
        void should_ReturnFalse_when_CoordinateIsOutOfBounds() {
            var grid = new Grid(1, 1);

            assertThat(grid.isWalkable(1, 0)).isFalse();
        }

        @Test
        @DisplayName("Returns the value assigned to a coordinate")
        void should_ReturnAssignedValue_when_CoordinateIsInBounds() {
            var grid = new Grid(2, 2);

            grid.setWalkable(1, 1, true);

            assertThat(grid.isWalkable(1, 1)).isTrue();
        }

        @Test
        @DisplayName("Returns the value assigned to a position")
        void should_ReturnAssignedValue_when_PositionIsProvided() {
            var grid = new Grid(2, 2);
            var position = new GridPos(1, 1);

            grid.setWalkable(1, 1, true);

            assertThat(grid.isWalkable(position)).isTrue();
        }
    }

    @Nested
    @DisplayName("setWalkable")
    class SetWalkableMethodTests {

        @Test
        @DisplayName("Updates the walkability of an in-bounds coordinate")
        void should_UpdateWalkability_when_CoordinateIsInBounds() {
            var grid = new Grid(1, 1);

            grid.setWalkable(0, 0, true);
            assertThat(grid.isWalkable(0, 0)).isTrue();

            grid.setWalkable(0, 0, false);
            assertThat(grid.isWalkable(0, 0)).isFalse();
        }

        @Test
        @DisplayName("Rejects an out-of-bounds coordinate")
        void should_RejectCoordinate_when_CoordinateIsOutOfBounds() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Grid(1, 1).setWalkable(1, 0, true)
            );
        }
    }
}
