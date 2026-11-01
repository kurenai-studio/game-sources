package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class WarehouseConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid warehouse constraints")
        void should_RetainConstraints_when_ValuesAreValid() {
            var config = new WarehouseConfig(
                    100,
                    0
            );
            assertThat(config.backlogLimit()).isZero();
        }

        @Test
        @DisplayName("Rejects a non-positive battery capacity")
        void should_RejectBatteryCapacity_when_BatteryCapacityIsNotPositive() {
            assertThatIllegalArgumentException().isThrownBy(() -> new WarehouseConfig(
                    0,
                    3
            ));
        }

        @Test
        @DisplayName("Rejects a negative backlog limit")
        void should_RejectBacklogLimit_when_BacklogLimitIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() -> new WarehouseConfig(
                    100,
                    -1
            ));
        }
    }
}
