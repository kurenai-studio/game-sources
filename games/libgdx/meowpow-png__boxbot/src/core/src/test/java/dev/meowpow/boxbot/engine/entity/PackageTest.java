package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.PackageColor;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class PackageTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null package id")
        void should_RejectId_when_PackageIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Package(null, PackageColor.RED));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null color")
        void should_RejectColor_when_ColorIsNull() {
            var id = new PackageId(1);
            assertThatNullPointerException().isThrownBy(() -> new Package(id, null));
        }
    }
}
