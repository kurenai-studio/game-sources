package dev.meowpow.boxbot.engine.spatial.grid;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class TileExtentTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains non-negative dimensions")
        void should_RetainDimensions_when_DimensionsAreNonNegative() {
            var extent = new TileExtent(2, 3);

            assertThat(extent.widthTiles()).isEqualTo(2);
            assertThat(extent.heightTiles()).isEqualTo(3);
        }

        @Test
        @DisplayName("Accepts zero dimensions")
        void should_AcceptDimensions_when_DimensionsAreZero() {
            var extent = new TileExtent(0, 0);

            assertThat(extent.widthTiles()).isZero();
            assertThat(extent.heightTiles()).isZero();
        }

        @Test
        @DisplayName("Rejects a negative width")
        void should_RejectWidth_when_WidthIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TileExtent(-1, 0)
            );
        }

        @Test
        @DisplayName("Rejects a negative height")
        void should_RejectHeight_when_HeightIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TileExtent(0, -1)
            );
        }
    }
}
