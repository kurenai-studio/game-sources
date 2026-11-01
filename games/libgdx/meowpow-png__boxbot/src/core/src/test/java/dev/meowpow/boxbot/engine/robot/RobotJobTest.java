package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.ShelfId;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class RobotJobTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null job identifier")
        void should_RejectJobId_when_JobIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotJob(
                    null,
                    JobType.PUTAWAY,
                    new ShelfId(1),
                    packageWithId(1),
                    0
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null job type")
        void should_RejectJobType_when_JobTypeIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotJob(
                    new JobId("job-1"),
                    null,
                    new ShelfId(1),
                    packageWithId(1),
                    0
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null package")
        void should_RejectPackage_when_PackageIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotJob(
                    new JobId("job-1"),
                    JobType.PUTAWAY,
                    new ShelfId(1),
                    null,
                    0
            ));
        }
    }
}
