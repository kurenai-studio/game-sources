package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class DemandConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid demand settings")
        void should_RetainDemandSettings_when_ValuesAreValid() {
            var config = new DemandConfig(
                    0.25,
                    20,
                    30,
                    0,
                    40,
                    2,
                    5,
                    supply(),
                    demandCycle()
            );
            assertThat(config.truckCapacity()).isEqualTo(5);
        }

        @Test
        @DisplayName("Rejects an invalid truck capacity")
        void should_RejectTruckCapacity_when_TruckCapacityIsNotPositive() {
            assertThatIllegalArgumentException().isThrownBy(() -> new DemandConfig(
                    0.25,
                    20,
                    30,
                    5,
                    40,
                    2,
                    0,
                    supply(),
                    demandCycle()
            ));
        }

        @Test
        @DisplayName("Rejects invalid demand intervals and thresholds")
        void should_RejectDemandSettings_when_AValueIsOutsideItsRange() {
            assertThatIllegalArgumentException().isThrownBy(() -> new DemandConfig(
                    Double.NaN,
                    20,
                    30,
                    5,
                    40,
                    2,
                    5,
                    supply(),
                    demandCycle()
            ));
            assertThatIllegalArgumentException().isThrownBy(() -> new DemandConfig(
                    0.25,
                    0,
                    30,
                    5,
                    40,
                    2,
                    5,
                    supply(),
                    demandCycle()
            ));
            assertThatIllegalArgumentException().isThrownBy(() -> new DemandConfig(
                    0.25,
                    20,
                    30,
                    5,
                    0,
                    2,
                    5,
                    supply(),
                    demandCycle()
            ));
            assertThatIllegalArgumentException().isThrownBy(() -> new DemandConfig(
                    0.25,
                    20,
                    0,
                    -1,
                    40,
                    0,
                    5,
                    supply(),
                    demandCycle()
            ));
        }
    }

    private static SupplyConfig supply() {
        return new SupplyConfig(2400, 0.35, 0.15);
    }

    private static DemandCycleConfig demandCycle() {
        return new DemandCycleConfig(800, 0.5, 1.5);
    }
}
