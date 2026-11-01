package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.ShelfId;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

class ControllerDecisionTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("TakeJob retains a valid job identifier")
        void should_RetainJobId_when_TakeJobJobIdIsValid() {
            var jobId = new JobId("job-123");
            var actual = new ControllerDecision.TakeJob(jobId).jobId();

            assertThat(actual).isEqualTo(jobId);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("TakeJob rejects a null job identifier")
        void should_RejectNullJobId_when_TakeJobJobIdIsNull() {
            var thrown = catchThrowable(() ->
                    new ControllerDecision.TakeJob(null)
            );
            assertThat(thrown).isInstanceOf(NullPointerException.class);
        }

        @Test
        @DisplayName("Retrieve retains a valid shelf identifier")
        void should_RetainShelfId_when_RetrieveShelfIdIsValid() {
            var shelfId = new ShelfId(0);
            var action = new ControllerDecision.Retrieve(shelfId);

            assertThat(action.shelfId()).isEqualTo(shelfId);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Retrieve rejects a null shelf identifier")
        void should_RejectShelfId_when_RetrieveShelfIdIsNull() {
            var thrown = catchThrowable(() ->
                    new ControllerDecision.Retrieve(null)
            );
            assertThat(thrown).isInstanceOf(NullPointerException.class);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("StoreAt rejects a null shelf identifier")
        void should_RejectNullShelfId_when_StoreAtShelfIdIsNull() {
            var thrown = catchThrowable(() ->
                    new ControllerDecision.StoreAt(null)
            );
            assertThat(thrown).isInstanceOf(NullPointerException.class);
        }

        @Test
        @DisplayName("StoreAt retains a valid shelf identifier")
        void should_RetainShelfId_when_StoreAtShelfIdIsValid() {
            var shelfId = new ShelfId(0);
            var actual = new ControllerDecision.StoreAt(shelfId).shelfId();

            assertThat(actual).isEqualTo(shelfId);
        }

        @Test
        @DisplayName("Creates every no-argument action")
        void should_CreateEveryNoArgumentAction_when_Constructed() {
            assertThat(new ControllerDecision.Charge()).isInstanceOf(ControllerDecision.class);
            assertThat(new ControllerDecision.GoToBay()).isInstanceOf(ControllerDecision.class);
            assertThat(new ControllerDecision.Idle()).isInstanceOf(ControllerDecision.class);
        }
    }
}
