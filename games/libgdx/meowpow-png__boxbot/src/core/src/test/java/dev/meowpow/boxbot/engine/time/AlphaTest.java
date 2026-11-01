package dev.meowpow.boxbot.engine.time;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class AlphaTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains a valid interpolation fraction")
        void should_RetainValue_when_ValueIsWithinRange() {
            var alpha = new Alpha(0.75f);

            assertThat(alpha.value()).isEqualTo(0.75f);
        }

        @Test
        @DisplayName("Rejects a value below zero")
        void should_RejectValue_when_ValueIsBelowZero() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Alpha(-0.01f)
            );
        }

        @Test
        @DisplayName("Rejects a value above one")
        void should_RejectValue_when_ValueIsAboveOne() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Alpha(1.01f)
            );
        }

        @Test
        @DisplayName("Rejects a non-numeric value")
        void should_RejectValue_when_ValueIsNotANumber() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new Alpha(Float.NaN)
            );
        }
    }
}
