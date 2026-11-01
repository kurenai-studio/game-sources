package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class UiConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid display settings")
        void should_RetainDisplaySettings_when_ValuesAreValid() {
            var config = new UiConfig(
                    0.5,
                    0.2
            );
            assertThat(config.orderWarningThresholdPercent()).isEqualTo(0.5);
            assertThat(config.orderCriticalThresholdPercent()).isEqualTo(0.2);
        }

        @Test
        @DisplayName("Rejects an invalid order threshold")
        void should_RejectOrderThreshold_when_CriticalThresholdExceedsWarningThreshold() {
            assertThatIllegalArgumentException().isThrownBy(() -> new UiConfig(
                            0.2,
                            0.5
                    )
            );
        }

        @Test
        @DisplayName("Rejects NaN order thresholds")
        void should_RejectOrderThreshold_when_ThresholdIsNaN() {
            assertThatIllegalArgumentException().isThrownBy(() -> new UiConfig(
                            Double.NaN,
                            0.2
                    )
            );
        }
    }
}
