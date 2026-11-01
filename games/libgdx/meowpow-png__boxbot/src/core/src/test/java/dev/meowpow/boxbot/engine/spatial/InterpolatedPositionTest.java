package dev.meowpow.boxbot.engine.spatial;

import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.engine.time.Alpha;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class InterpolatedPositionTest {

    private static final TileSize TILE_SIZE = new TileSize(32);

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null starting position")
        void should_RejectFrom_when_FromIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new InterpolatedPosition(
                    null,
                    new GridPos(0, 0),
                    new Alpha(0f)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null ending position")
        void should_RejectTo_when_ToIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new InterpolatedPosition(
                    new GridPos(0, 0),
                    null,
                    new Alpha(0f)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null alpha")
        void should_RejectAlpha_when_AlphaIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(0, 0),
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
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(2, 0),
                    new Alpha(0f)
            );
            position.set(
                    new GridPos(2, 0),
                    new GridPos(4, 0),
                    new Alpha(0.5f)
            );
            assertThat(position.centerX(TILE_SIZE)).isEqualTo(112f);
        }
    }

    @Nested
    @DisplayName("centerX")
    class CenterXMethodTests {

        @Test
        @DisplayName("Returns the from position's center when alpha is zero")
        void should_ReturnFromPositionCenter_when_AlphaIsZero() {
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(2, 0),
                    new Alpha(0f)
            );
            assertThat(position.centerX(TILE_SIZE)).isEqualTo(16f);
        }

        @Test
        @DisplayName("Returns the to position's center when alpha is one")
        void should_ReturnToPositionCenter_when_AlphaIsOne() {
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(2, 0),
                    new Alpha(1f)
            );
            assertThat(position.centerX(TILE_SIZE)).isEqualTo(80f);
        }

        @Test
        @DisplayName("Returns the midpoint when alpha is halfway")
        void should_ReturnMidpoint_when_AlphaIsHalfway() {
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(2, 0),
                    new Alpha(0.5f)
            );
            assertThat(position.centerX(TILE_SIZE)).isEqualTo(48f);
        }
    }

    @Nested
    @DisplayName("centerY")
    class CenterYMethodTests {

        @Test
        @DisplayName("Returns the from position's center when alpha is zero")
        void should_ReturnFromPositionCenter_when_AlphaIsZero() {
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(0, 2),
                    new Alpha(0f)
            );
            assertThat(position.centerY(TILE_SIZE)).isEqualTo(16f);
        }

        @Test
        @DisplayName("Returns the to position's center when alpha is one")
        void should_ReturnToPositionCenter_when_AlphaIsOne() {
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(0, 2),
                    new Alpha(1f)
            );
            assertThat(position.centerY(TILE_SIZE)).isEqualTo(80f);
        }

        @Test
        @DisplayName("Returns the midpoint when alpha is halfway")
        void should_ReturnMidpoint_when_AlphaIsHalfway() {
            var position = new InterpolatedPosition(
                    new GridPos(0, 0),
                    new GridPos(0, 2),
                    new Alpha(0.5f)
            );
            assertThat(position.centerY(TILE_SIZE)).isEqualTo(48f);
        }
    }
}
