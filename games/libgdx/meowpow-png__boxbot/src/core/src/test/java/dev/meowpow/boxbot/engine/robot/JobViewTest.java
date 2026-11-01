package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class JobViewTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains all supplied values")
        void should_RetainValues_when_ArgumentsAreValid() {
            var jobId = new JobId("job-123");
            var shelfId = new ShelfId(4);
            var packageId = new PackageId(7);

            var jobView = new JobView(
                    jobId,
                    JobType.PUTAWAY,
                    shelfId,
                    packageId,
                    PackageColor.RED
            );
            assertThat(jobView.jobId()).isEqualTo(jobId);
            assertThat(jobView.type()).isEqualTo(JobType.PUTAWAY);
            assertThat(jobView.shelfId()).isEqualTo(shelfId);
            assertThat(jobView.packageId()).isEqualTo(packageId);
            assertThat(jobView.color()).isEqualTo(PackageColor.RED);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null job identifier")
        void should_RejectNullJobId_when_JobIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new JobView(
                    null,
                    JobType.PUTAWAY,
                    new ShelfId(4),
                    new PackageId(7),
                    PackageColor.RED
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null job type")
        void should_RejectNullType_when_TypeIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new JobView(
                    new JobId("job-123"),
                    null,
                    new ShelfId(4),
                    new PackageId(7),
                    PackageColor.RED
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null shelf identifier")
        void should_RejectNullShelfId_when_ShelfIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new JobView(
                    new JobId("job-123"),
                    JobType.PUTAWAY,
                    null,
                    new PackageId(7),
                    PackageColor.RED
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null package identifier")
        void should_RejectNullPackageId_when_PackageIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new JobView(
                    new JobId("job-123"),
                    JobType.PUTAWAY,
                    new ShelfId(4),
                    null,
                    PackageColor.RED
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null color")
        void should_RejectNullColor_when_ColorIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new JobView(
                    new JobId("job-123"),
                    JobType.PUTAWAY,
                    new ShelfId(4),
                    new PackageId(7),
                    null
            ));
        }
    }
}
