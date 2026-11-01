package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class SupplyConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid supply settings")
        void should_RetainSupplySettings_when_ValuesAreValid() {
            var config = new SupplyConfig(2400, 0.35, 0.15);

            assertThat(config.cycleLengthTicks()).isEqualTo(2400);
            assertThat(config.minimumFactor()).isEqualTo(0.35);
            assertThat(config.floorFraction()).isEqualTo(0.15);
        }

        @Test
        @DisplayName("Rejects a non-positive or odd cycle length")
        void should_RejectCycleLength_when_ItCannotHaveTwoEqualPhases() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(0, 0.35, 0.15)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2399, 0.35, 0.15)
            );
        }

        @Test
        @DisplayName("Rejects an invalid minimum factor")
        void should_RejectMinimumFactor_when_OutsideItsSupportedRange() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2400, 0, 0.15)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2400, 1.01, 0.15)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2400, Double.NaN, 0.15)
            );
        }

        @Test
        @DisplayName("Rejects an invalid floor fraction")
        void should_RejectFloorFraction_when_OutsideItsSupportedRange() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2400, 0.35, -0.01)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2400, 0.35, 1.01)
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new SupplyConfig(2400, 0.35, Double.POSITIVE_INFINITY)
            );
        }
    }
}
