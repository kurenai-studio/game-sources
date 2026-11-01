package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class InputConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains a positive queue limit")
        void should_RetainQueueLimit_when_QueueLimitIsPositive() {
            assertThat(new InputConfig(5)
                    .selectionQueueLimit()).isEqualTo(5);
        }

        @Test
        @DisplayName("Rejects a non-positive queue limit")
        void should_RejectQueueLimit_when_QueueLimitIsNotPositive() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new InputConfig(0)
            );
        }
    }
}
