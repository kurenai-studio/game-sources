package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class DemandCycleConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid demand-cycle settings")
        void should_RetainDemandCycleSettings_when_ValuesAreValid() {
            var config = new DemandCycleConfig(800, 0.5, 1.5);

            assertThat(config.cycleLengthTicks()).isEqualTo(800);
            assertThat(config.minimumRateFactor()).isEqualTo(0.5);
            assertThat(config.maximumRateFactor()).isEqualTo(1.5);
        }

        @Test
        @DisplayName("Rejects a non-positive or odd cycle length")
        void should_RejectCycleLength_when_ItCannotHaveTwoEqualPhases() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new DemandCycleConfig(0, 0.5, 1.5)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new DemandCycleConfig(801, 0.5, 1.5)
            );
        }

        @Test
        @DisplayName("Rejects an invalid minimum rate factor")
        void should_RejectMinimumRateFactor_when_ItIsNotPositiveAndFinite() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new DemandCycleConfig(800, 0, 1.5)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new DemandCycleConfig(800, Double.NaN, 1.5)
            );
        }

        @Test
        @DisplayName("Rejects a maximum rate factor below the minimum")
        void should_RejectMaximumRateFactor_when_ItIsBelowTheMinimum() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new DemandCycleConfig(800, 0.5, 0.49)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new DemandCycleConfig(800, 0.5, Double.POSITIVE_INFINITY)
            );
        }
    }
}
