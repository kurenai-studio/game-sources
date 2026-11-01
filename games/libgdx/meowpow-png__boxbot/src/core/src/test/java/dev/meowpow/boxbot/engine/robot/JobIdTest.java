package dev.meowpow.boxbot.engine.robot;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class JobIdTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains a non-blank value")
        void should_RetainValue_when_ValueIsNonBlank() {
            var jobId = new JobId("job-123");

            assertThat(jobId.value()).isEqualTo("job-123");
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null value")
        void should_RejectNullValue_when_ValueIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new JobId(null)
            );
        }

        @Test
        @DisplayName("Rejects a blank value")
        void should_RejectBlankValue_when_ValueIsBlank() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new JobId("   ")
            );
        }
    }
}
