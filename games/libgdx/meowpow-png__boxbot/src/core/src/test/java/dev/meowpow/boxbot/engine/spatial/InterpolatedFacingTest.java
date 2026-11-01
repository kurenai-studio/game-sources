package dev.meowpow.boxbot.engine.spatial;

import dev.meowpow.boxbot.engine.spatial.grid.Direction;
import dev.meowpow.boxbot.engine.time.Alpha;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;
import static org.assertj.core.data.Offset.offset;

class InterpolatedFacingTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null starting direction")
        void should_RejectFrom_when_FromIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new InterpolatedFacing(
                    null,
                    Direction.NORTH,
                    new Alpha(0f)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null ending direction")
        void should_RejectTo_when_ToIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new InterpolatedFacing(
                    Direction.NORTH,
                    null,
                    new Alpha(0f)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null alpha")
        void should_RejectAlpha_when_AlphaIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new InterpolatedFacing(
                    Direction.NORTH,
                    Direction.NORTH,
                    null
            ));
        }
    }

    @Nested
    @DisplayName("set")
    class SetMethodTests {

        @Test
        @DisplayName("Updates the interpolation")
        void should_UpdateInterpolation_when_NewValuesAreSet() {
            var facing = new InterpolatedFacing(
                    Direction.NORTH,
                    Direction.WEST,
                    new Alpha(0f)
            );
            facing.set(
                    Direction.WEST,
                    Direction.SOUTH,
                    new Alpha(0.5f)
            );
            assertThat(facing.degrees()).isEqualTo(135f);
        }
    }

    @Nested
    @DisplayName("degrees")
    class DegreesMethodTests {

        @Test
        @DisplayName("Returns the from direction's angle when alpha is zero")
        void should_ReturnFromAngle_when_AlphaIsZero() {
            var facing = new InterpolatedFacing(
                    Direction.NORTH,
                    Direction.WEST,
                    new Alpha(0f)
            );
            assertThat(facing.degrees()).isEqualTo(0f);
        }

        @Test
        @DisplayName("Returns the to direction's angle when alpha is one")
        void should_ReturnToAngle_when_AlphaIsOne() {
            var facing = new InterpolatedFacing(
                    Direction.NORTH,
                    Direction.WEST,
                    new Alpha(1f)
            );
            assertThat(facing.degrees()).isEqualTo(90f);
        }

        @Test
        @DisplayName("Interpolates directly between non-wrapping angles")
        void should_InterpolateDirectly_when_AnglesDoNotWrap() {
            var facing = new InterpolatedFacing(
                    Direction.NORTH,
                    Direction.WEST,
                    new Alpha(0.5f)
            );
            assertThat(facing.degrees()).isEqualTo(45f);
        }

        @Test
        @DisplayName("Takes the shortest path around the wrap point when turning from EAST to NORTH")
        void should_TakeShortestPath_when_TurningPastZeroDegrees() {
            var facing = new InterpolatedFacing(
                    Direction.EAST,
                    Direction.NORTH,
                    new Alpha(0.5f)
            );
            assertThat(facing.degrees()).isCloseTo(315f, offset(0.001f));
        }

        @Test
        @DisplayName("Takes the counterclockwise half-turn when directions are opposite")
        void should_TakeCounterclockwiseHalfTurn_when_DirectionsAreOpposite() {
            var facing = new InterpolatedFacing(
                    Direction.NORTH,
                    Direction.SOUTH,
                    new Alpha(0.5f)
            );
            assertThat(facing.degrees()).isEqualTo(-90f);
        }
    }
}
