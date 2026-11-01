package dev.meowpow.boxbot.engine.time;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class TickAccumulatorTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a zero tick duration")
        void should_RejectTickDuration_when_TickDurationIsZero() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TickAccumulator(0f)
            );
        }

        @Test
        @DisplayName("Rejects a negative tick duration")
        void should_RejectTickDuration_when_TickDurationIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TickAccumulator(-1f)
            );
        }

        @Test
        @DisplayName("Rejects a non-numeric tick duration")
        void should_RejectTickDuration_when_TickDurationIsNotANumber() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TickAccumulator(Float.NaN)
            );
        }
    }

    @Nested
    @DisplayName("update")
    class UpdateMethodTests {

        @Test
        @DisplayName("Returns zero when the delta is below the tick duration")
        void should_ReturnZero_when_DeltaIsBelowTickDuration() {
            var accumulator = new TickAccumulator(1f);

            int tickCount = accumulator.update(0.9f);

            assertThat(tickCount).isZero();
        }

        @Test
        @DisplayName("Returns one when the delta reaches the tick duration")
        void should_ReturnOne_when_DeltaReachesTickDuration() {
            var accumulator = new TickAccumulator(1f);

            int tickCount = accumulator.update(1f);

            assertThat(tickCount).isEqualTo(1);
        }

        @Test
        @DisplayName("Returns multiple ticks when the delta spans multiple tick durations")
        void should_ReturnMultipleTicks_when_DeltaSpansMultipleTickDurations() {
            var accumulator = new TickAccumulator(1f);

            int tickCount = accumulator.update(3.5f);

            assertThat(tickCount).isEqualTo(3);
        }

        @Test
        @DisplayName("Carries over leftover time when accumulated across multiple updates")
        void should_CarryOverLeftoverTime_when_AccumulatedAcrossMultipleUpdates() {
            var accumulator = new TickAccumulator(1f);

            accumulator.update(0.6f);
            int tickCount = accumulator.update(0.5f);

            assertThat(tickCount).isEqualTo(1);
        }
    }

    @Nested
    @DisplayName("alpha")
    class AlphaMethodTests {

        @Test
        @DisplayName("Returns zero when no time has accumulated")
        void should_ReturnZero_when_NoTimeHasAccumulated() {
            var accumulator = new TickAccumulator(1f);

            assertThat(accumulator.alpha().value()).isZero();
        }

        @Test
        @DisplayName("Returns the fractional progress towards the next tick")
        void should_ReturnFractionalProgress_when_PartwayThroughATick() {
            var accumulator = new TickAccumulator(2f);

            accumulator.update(1.5f);

            assertThat(accumulator.alpha().value()).isEqualTo(0.75f);
        }

        @Test
        @DisplayName("Mutates the same alpha instance after an update")
        void should_MutateSameAlpha_when_AccumulatorIsUpdated() {
            var accumulator = new TickAccumulator(1f);
            var alpha = accumulator.alpha();

            accumulator.update(0.5f);

            assertThat(accumulator.alpha()).isSameAs(alpha);
            assertThat(alpha.value()).isEqualTo(0.5f);
        }
    }
}
