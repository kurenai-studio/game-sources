package dev.meowpow.boxbot.engine.robot;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class FailuresTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains zero count and limit")
        void should_RetainZeroValues_when_CountAndLimitAreZero() {
            var failures = new Failures(0, 0);

            assertThat(failures.count()).isZero();
            assertThat(failures.limit()).isZero();
        }

        @Test
        @DisplayName("Rejects a negative count")
        void should_RejectNegativeCount_when_CountIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Failures(-1, 0)
            );
        }

        @Test
        @DisplayName("Rejects a negative limit")
        void should_RejectNegativeLimit_when_LimitIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Failures(0, -1)
            );
        }
    }
}
