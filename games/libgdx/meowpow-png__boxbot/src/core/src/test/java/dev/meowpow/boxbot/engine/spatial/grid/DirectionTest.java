package dev.meowpow.boxbot.engine.spatial.grid;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class DirectionTest {

    @Nested
    @DisplayName("degrees")
    class DegreesMethodTests {

        @Test
        @DisplayName("Returns the cardinal angles")
        void should_ReturnCardinalAngles_when_Queried() {
            assertThat(Direction.NORTH.degrees()).isZero();
            assertThat(Direction.WEST.degrees()).isEqualTo(90f);
            assertThat(Direction.SOUTH.degrees()).isEqualTo(180f);
            assertThat(Direction.EAST.degrees()).isEqualTo(270f);
        }
    }

    @Nested
    @DisplayName("between")
    class BetweenMethodTests {

        @Test
        @DisplayName("Returns EAST when x increases")
        void should_ReturnEast_when_XIncreases() {
            var direction = Direction.between(
                    new GridPos(0, 0),
                    new GridPos(1, 0)
            );
            assertThat(direction).isEqualTo(Direction.EAST);
        }

        @Test
        @DisplayName("Returns WEST when x decreases")
        void should_ReturnWest_when_XDecreases() {
            var direction = Direction.between(
                    new GridPos(1, 0),
                    new GridPos(0, 0)
            );
            assertThat(direction).isEqualTo(Direction.WEST);
        }

        @Test
        @DisplayName("Returns NORTH when y increases")
        void should_ReturnNorth_when_YIncreases() {
            var direction = Direction.between(
                    new GridPos(0, 0),
                    new GridPos(0, 1)
            );
            assertThat(direction).isEqualTo(Direction.NORTH);
        }

        @Test
        @DisplayName("Returns SOUTH when y decreases")
        void should_ReturnSouth_when_YDecreases() {
            var direction = Direction.between(
                    new GridPos(0, 1),
                    new GridPos(0, 0)
            );
            assertThat(direction).isEqualTo(Direction.SOUTH);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null starting position")
        void should_RejectNullFrom_when_FromIsNull() {
            assertThatNullPointerException().isThrownBy(() -> Direction.between(
                    null,
                    new GridPos(0, 0)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null destination position")
        void should_RejectNullTo_when_ToIsNull() {
            assertThatNullPointerException().isThrownBy(() -> Direction.between(
                    new GridPos(0, 0),
                    null
            ));
        }

        @Test
        @DisplayName("Rejects a step that is not orthogonal")
        void should_RejectStep_when_StepIsNotOrthogonal() {
            assertThatIllegalArgumentException().isThrownBy(() -> Direction.between(
                    new GridPos(0, 0),
                    new GridPos(1, 1)
            ));
        }

        @Test
        @DisplayName("Rejects a distant step whose delta exceeds an integer")
        void should_RejectStep_when_DeltaExceedsIntegerRange() {
            assertThatIllegalArgumentException().isThrownBy(() -> Direction.between(
                    new GridPos(Integer.MIN_VALUE, 0),
                    new GridPos(Integer.MAX_VALUE, 0)
            ));
        }
    }
}
