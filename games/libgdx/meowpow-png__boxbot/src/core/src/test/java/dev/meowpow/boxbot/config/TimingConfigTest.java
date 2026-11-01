package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class TimingConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains positive tick durations")
        void should_RetainDurations_when_AllDurationsArePositive() {
            var config = new TimingConfig(
                    0.125f,
                    0.75f,
                    0.5f,
                    0.5f
            );
            assertThat(config.simulationTickDuration()).isEqualTo(0.5f);
            assertThat(config.robotChargingTickDuration()).isEqualTo(0.5f);
        }

        @Test
        @DisplayName("Rejects a non-positive tick duration")
        void should_RejectDuration_when_AnyDurationIsNotPositive() {
            assertThatIllegalArgumentException().isThrownBy(() -> new TimingConfig(
                    0,
                    0.75f,
                    0.5f,
                    0.5f
            ));
            assertThatIllegalArgumentException().isThrownBy(() -> new TimingConfig(
                    0.125f,
                    0.75f,
                    0,
                    0.5f
            ));
        }

        @Test
        @DisplayName("Rejects NaN tick durations")
        void should_RejectDuration_when_AnyDurationIsNaN() {
            assertThatIllegalArgumentException().isThrownBy(() -> new TimingConfig(
                    0.125f,
                    Float.NaN,
                    0.5f,
                    0.5f
            ));
        }
    }
}
