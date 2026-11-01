package dev.meowpow.boxbot.engine.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class ChargingStationTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null footprint")
        void should_RejectFootprint_when_FootprintIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new ChargingStation(null));
        }
    }
}
