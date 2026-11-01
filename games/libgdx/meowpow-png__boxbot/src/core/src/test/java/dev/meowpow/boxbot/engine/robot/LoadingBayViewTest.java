package dev.meowpow.boxbot.engine.robot;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class LoadingBayViewTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains zero free and total tiles")
        void should_RetainZeroValues_when_FreeAndTotalTilesAreZero() {
            var loadingBayView = new LoadingBayView(0, 0);

            assertThat(loadingBayView.freeTiles()).isZero();
            assertThat(loadingBayView.totalTiles()).isZero();
        }

        @Test
        @DisplayName("Rejects a negative total tile count")
        void should_RejectNegativeTotalTiles_when_TotalTilesIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new LoadingBayView(0, -1)
            );
        }

        @Test
        @DisplayName("Rejects a negative free tile count")
        void should_RejectNegativeFreeTiles_when_FreeTilesIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new LoadingBayView(-1, 0)
            );
        }

        @Test
        @DisplayName("Rejects free tiles above total capacity")
        void should_RejectFreeTilesAboveTotalTiles_when_FreeTilesExceedTotalTiles() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new LoadingBayView(2, 1)
            );
        }
    }
}
