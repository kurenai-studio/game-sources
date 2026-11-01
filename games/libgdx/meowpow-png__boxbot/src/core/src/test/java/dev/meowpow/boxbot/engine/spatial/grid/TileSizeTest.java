package dev.meowpow.boxbot.engine.spatial.grid;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class TileSizeTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains a positive pixel size")
        void should_RetainPixels_when_PixelsArePositive() {
            assertThat(new TileSize(16).pixels()).isEqualTo(16);
        }

        @Test
        @DisplayName("Rejects zero pixels")
        void should_RejectPixels_when_PixelsAreZero() {
            assertThatIllegalArgumentException().isThrownBy(() -> new TileSize(0));
        }

        @Test
        @DisplayName("Rejects negative pixels")
        void should_RejectPixels_when_PixelsAreNegative() {
            assertThatIllegalArgumentException().isThrownBy(() -> new TileSize(-1));
        }
    }
}
