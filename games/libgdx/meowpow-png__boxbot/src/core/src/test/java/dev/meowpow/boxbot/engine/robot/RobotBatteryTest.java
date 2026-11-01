package dev.meowpow.boxbot.engine.robot;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class RobotBatteryTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a negative capacity")
        void should_RejectNegativeCapacity_when_CapacityIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new RobotBattery(0, -1)
            );
        }

        @Test
        @DisplayName("Rejects a negative level")
        void should_RejectNegativeLevel_when_LevelIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new RobotBattery(-1, 10)
            );
        }

        @Test
        @DisplayName("Rejects a level above capacity")
        void should_RejectLevelAboveCapacity_when_LevelExceedsCapacity() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new RobotBattery(11, 10)
            );
        }
    }

    @Nested
    @DisplayName("full")
    class FullMethodTests {

        @Test
        @DisplayName("Creates a battery at full capacity")
        void should_CreateFullBattery_when_CapacityIsValid() {
            var battery = RobotBattery.full(10);

            assertThat(battery.level()).isEqualTo(10);
            assertThat(battery.capacity()).isEqualTo(10);
        }
    }

    @Nested
    @DisplayName("drain")
    class DrainMethodTests {

        @Test
        @DisplayName("Reduces the level by the requested amount")
        void should_ReduceLevel_when_AmountIsWithinCurrentLevel() {
            var battery = new RobotBattery(8, 10);

            battery.drain(3);

            assertThat(battery.level()).isEqualTo(5);
            assertThat(battery.capacity()).isEqualTo(10);
        }

        @Test
        @DisplayName("Clamps the level at zero")
        void should_ClampLevelAtZero_when_AmountExceedsCurrentLevel() {
            var battery = new RobotBattery(3, 10);

            battery.drain(4);

            assertThat(battery.level()).isZero();
        }
    }

    @Nested
    @DisplayName("charge")
    class ChargeMethodTests {

        @Test
        @DisplayName("Increases the level by the requested amount")
        void should_IncreaseLevel_when_AmountFitsWithinCapacity() {
            var battery = new RobotBattery(3, 10);

            battery.charge(4);

            assertThat(battery.level()).isEqualTo(7);
            assertThat(battery.capacity()).isEqualTo(10);
        }

        @Test
        @DisplayName("Clamps the level at capacity")
        void should_ClampLevelAtCapacity_when_AmountExceedsRemainingCapacity() {
            var battery = new RobotBattery(8, 10);

            battery.charge(3);

            assertThat(battery.level()).isEqualTo(10);
        }
    }

    @Nested
    @DisplayName("percentage")
    class PercentageMethodTests {

        @Test
        @DisplayName("Returns the percentage rounded down")
        void should_ReturnPercentageRoundedDown_when_CapacityIsNonZero() {
            var battery = new RobotBattery(2, 3);

            assertThat(battery.percentage()).isEqualTo(66);
        }

        @Test
        @DisplayName("Returns zero when capacity is zero")
        void should_ReturnZero_when_CapacityIsZero() {
            var battery = new RobotBattery(0, 0);

            assertThat(battery.percentage()).isZero();
        }
    }

    @Nested
    @DisplayName("isLow")
    class IsLowMethodTests {

        @Test
        @DisplayName("Returns true when the level equals the threshold")
        void should_ReturnTrue_when_LevelEqualsThreshold() {
            var battery = new RobotBattery(3, 10);

            assertThat(battery.isLow(3)).isTrue();
        }
    }

    @Nested
    @DisplayName("isFull")
    class IsFullMethodTests {

        @Test
        @DisplayName("Returns true when the level equals capacity")
        void should_ReturnTrue_when_LevelEqualsCapacity() {
            var battery = new RobotBattery(10, 10);

            assertThat(battery.isFull()).isTrue();
        }
    }

    @Nested
    @DisplayName("isDepleted")
    class IsDepletedMethodTests {

        @Test
        @DisplayName("Returns true when the level is zero")
        void should_ReturnTrue_when_LevelIsZero() {
            var battery = new RobotBattery(0, 10);

            assertThat(battery.isDepleted()).isTrue();
        }
    }
}
