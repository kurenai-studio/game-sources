package dev.meowpow.boxbot.engine.time;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class IntervalTimerTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a zero interval")
        void should_RejectInterval_when_IntervalIsZero() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new IntervalTimer(0)
            );
        }

        @Test
        @DisplayName("Rejects a negative interval")
        void should_RejectInterval_when_IntervalIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new IntervalTimer(-1)
            );
        }
    }

    @Nested
    @DisplayName("advance")
    class AdvanceMethodTests {

        @Test
        @DisplayName("Does not fire before the interval elapses")
        void should_NotFire_when_IntervalHasNotElapsed() {
            var timer = new IntervalTimer(3);

            assertThat(timer.advance()).isFalse();
        }

        @Test
        @DisplayName("Fires when the interval elapses")
        void should_Fire_when_IntervalHasElapsed() {
            var timer = new IntervalTimer(3);

            timer.advance();
            timer.advance();

            assertThat(timer.advance()).isTrue();
        }

        @Test
        @DisplayName("Fires again after a full interval following a firing")
        void should_FireAgain_when_FullIntervalHasElapsedSincePreviousFiring() {
            var timer = new IntervalTimer(2);

            timer.advance();
            timer.advance();

            assertThat(timer.advance()).isFalse();
            assertThat(timer.advance()).isTrue();
        }

        @Test
        @DisplayName("Fires on every tick for a one-tick interval")
        void should_Fire_when_IntervalIsOneTick() {
            var timer = new IntervalTimer(1);

            assertThat(timer.advance()).isTrue();
            assertThat(timer.advance()).isTrue();
        }
    }

    @Nested
    @DisplayName("ticksRemaining")
    class TicksRemainingMethodTests {

        @Test
        @DisplayName("Starts at the full interval")
        void should_StartAtFullInterval_when_NewlyCreated() {
            var timer = new IntervalTimer(3);

            assertThat(timer.ticksRemaining()).isEqualTo(3);
        }

        @Test
        @DisplayName("Decreases by one on each advance")
        void should_DecreaseByOne_when_Advanced() {
            var timer = new IntervalTimer(3);

            timer.advance();

            assertThat(timer.ticksRemaining()).isEqualTo(2);
        }

        @Test
        @DisplayName("Resets to the full interval after firing")
        void should_ResetToFullInterval_when_TimerFires() {
            var timer = new IntervalTimer(2);

            timer.advance();
            timer.advance();

            assertThat(timer.ticksRemaining()).isEqualTo(2);
        }
    }
}
