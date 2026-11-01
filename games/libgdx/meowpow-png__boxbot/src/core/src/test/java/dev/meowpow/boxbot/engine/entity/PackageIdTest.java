package dev.meowpow.boxbot.engine.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class PackageIdTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains zero as the lowest valid value")
        void should_RetainZero_when_ValueIsZero() {
            assertThat(new PackageId(0).value()).isZero();
        }

        @Test
        @DisplayName("Rejects a negative value")
        void should_RejectNegativeValue_when_ValueIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() -> new PackageId(-1));
        }
    }
}
