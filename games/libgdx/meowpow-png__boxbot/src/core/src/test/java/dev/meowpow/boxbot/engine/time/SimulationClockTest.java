package dev.meowpow.boxbot.engine.time;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SimulationClockTest {

    @Nested
    @DisplayName("currentTick")
    class CurrentTickMethodTests {

        @Test
        @DisplayName("Starts at zero")
        void should_StartAtZero_when_NewlyCreated() {
            var clock = new SimulationClock();

            assertThat(clock.currentTick()).isZero();
        }
    }

    @Nested
    @DisplayName("advance")
    class AdvanceMethodTests {

        @Test
        @DisplayName("Advances once per call")
        void should_AdvanceOnce_when_CalledRepeatedly() {
            var clock = new SimulationClock();

            clock.advance();
            clock.advance();

            assertThat(clock.currentTick()).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("elapsedSeconds")
    class ElapsedSecondsMethodTests {

        @Test
        @DisplayName("Starts at zero")
        void should_StartAtZero_when_NewlyCreated() {
            assertThat(new SimulationClock().elapsedSeconds()).isZero();
        }
    }

    @Nested
    @DisplayName("advanceRealTime")
    class AdvanceRealTimeMethodTests {

        @Test
        @DisplayName("Accumulates elapsed seconds across calls")
        void should_AccumulateElapsedSeconds_when_CalledRepeatedly() {
            var clock = new SimulationClock();

            clock.advanceRealTime(0.25f);
            clock.advanceRealTime(0.5f);

            assertThat(clock.elapsedSeconds()).isEqualTo(0.75f);
        }
    }

    @Nested
    @DisplayName("reset")
    class ResetMethodTests {

        @Test
        @DisplayName("Resets the current tick back to zero")
        void should_ResetCurrentTick_when_ClockHasAdvanced() {
            var clock = new SimulationClock();

            clock.advance();
            clock.advance();
            clock.reset();

            assertThat(clock.currentTick()).isZero();
        }

        @Test
        @DisplayName("Resets the elapsed real playtime back to zero")
        void should_ResetElapsedSeconds_when_ClockHasAdvanced() {
            var clock = new SimulationClock();

            clock.advanceRealTime(1.5f);
            clock.reset();

            assertThat(clock.elapsedSeconds()).isZero();
        }

        @Test
        @DisplayName("Leaves an already-reset clock unchanged")
        void should_LeaveClockUnchanged_when_ClockIsAlreadyReset() {
            var clock = new SimulationClock();

            clock.reset();

            assertThat(clock.currentTick()).isZero();
            assertThat(clock.elapsedSeconds()).isZero();
        }

        @Test
        @DisplayName("Allows the clock to advance again after resetting")
        void should_AllowAdvancing_when_ClockIsResetAfterAdvancing() {
            var clock = new SimulationClock();

            clock.advance();
            clock.reset();
            clock.advance();

            assertThat(clock.currentTick()).isEqualTo(1);
        }
    }
}
