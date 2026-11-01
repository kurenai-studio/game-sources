package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class RobotViewTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Accepts an empty-handed robot")
        void should_AcceptEmptyHandedRobot_when_CarriedPackageFieldsAreNull() {
            var robotView = new RobotView(
                    new GridPos(1, 2),
                    new RobotBattery(8, 10),
                    null,
                    null,
                    null
            );
            assertThat(robotView.carriedPackageId()).isNull();
            assertThat(robotView.carriedColor()).isNull();
            assertThat(robotView.carriedJobType()).isNull();
        }

        @Test
        @DisplayName("Retains a carried package and its details")
        void should_RetainCarriedPackageDetails_when_AllCarriedPackageFieldsArePresent() {
            var position = new GridPos(1, 2);
            var battery = new RobotBattery(8, 10);
            var packageId = new PackageId(7);

            var robotView = new RobotView(
                    position,
                    battery,
                    packageId,
                    PackageColor.BLUE,
                    JobType.RETRIEVAL
            );
            assertThat(robotView.position()).isEqualTo(position);
            assertThat(robotView.battery()).isEqualTo(battery);
            assertThat(robotView.carriedPackageId()).isEqualTo(packageId);
            assertThat(robotView.carriedColor()).isEqualTo(PackageColor.BLUE);
            assertThat(robotView.carriedJobType()).isEqualTo(JobType.RETRIEVAL);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null position")
        void should_RejectNullPosition_when_PositionIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotView(
                    null,
                    new RobotBattery(8, 10),
                    null,
                    null,
                    null
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null battery")
        void should_RejectNullBattery_when_BatteryIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new RobotView(
                    new GridPos(1, 2),
                    null,
                    null,
                    null,
                    null
            ));
        }

        @Test
        @DisplayName("Rejects a carried color without a package")
        void should_RejectCarriedColor_when_CarriedPackageIdIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new RobotView(
                    new GridPos(1, 2),
                    new RobotBattery(8, 10),
                    null,
                    PackageColor.BLUE,
                    null
            ));
        }

        @Test
        @DisplayName("Rejects a package without its color")
        void should_RejectCarriedPackageId_when_CarriedColorIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new RobotView(
                    new GridPos(1, 2),
                    new RobotBattery(8, 10),
                    new PackageId(7),
                    null,
                    JobType.RETRIEVAL
            ));
        }

        @Test
        @DisplayName("Rejects a carried job type without a package")
        void should_RejectCarriedJobType_when_CarriedPackageIdIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new RobotView(
                    new GridPos(1, 2),
                    new RobotBattery(8, 10),
                    null,
                    null,
                    JobType.RETRIEVAL
            ));
        }

        @Test
        @DisplayName("Rejects a package without its job type")
        void should_RejectCarriedPackageId_when_CarriedJobTypeIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new RobotView(
                    new GridPos(1, 2),
                    new RobotBattery(8, 10),
                    new PackageId(7),
                    PackageColor.BLUE,
                    null
            ));
        }
    }
}
