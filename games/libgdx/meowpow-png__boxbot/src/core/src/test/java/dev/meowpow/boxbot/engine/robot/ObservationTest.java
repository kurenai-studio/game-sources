package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;

import com.badlogic.gdx.utils.Array;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class ObservationTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains a valid state")
        void should_RetainState_when_ArgumentsAreValid() {
            var robot = robotView();
            ArrayView<ShelfView> shelves = emptyView();
            ArrayView<JobView> jobs = emptyView();
            ArrayView<OrderView> orders = emptyView();
            var failures = new Failures(1, 3);
            var loadingBay = new LoadingBayView(2, 4);

            var observation = new Observation(
                    robot,
                    shelves,
                    jobs,
                    orders,
                    42,
                    failures,
                    loadingBay
            );
            assertThat(observation.robot()).isEqualTo(robot);
            assertThat(observation.shelves()).isSameAs(shelves);
            assertThat(observation.jobs()).isSameAs(jobs);
            assertThat(observation.orders()).isSameAs(orders);
            assertThat(observation.currentTick()).isEqualTo(42);
            assertThat(observation.failures()).isEqualTo(failures);
            assertThat(observation.loadingBay()).isEqualTo(loadingBay);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null robot")
        void should_RejectRobot_when_RobotIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Observation(
                    null,
                    emptyView(),
                    emptyView(),
                    emptyView(),
                    0,
                    new Failures(1, 3),
                    new LoadingBayView(2, 4)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null shelves view")
        void should_RejectShelves_when_ShelvesAreNull() {
            assertThatNullPointerException().isThrownBy(() -> new Observation(
                    robotView(),
                    null,
                    emptyView(),
                    emptyView(),
                    0,
                    new Failures(1, 3),
                    new LoadingBayView(2, 4)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null jobs view")
        void should_RejectJobs_when_JobsAreNull() {
            assertThatNullPointerException().isThrownBy(() -> new Observation(
                    robotView(),
                    emptyView(),
                    null,
                    emptyView(),
                    0,
                    new Failures(1, 3),
                    new LoadingBayView(2, 4)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null orders view")
        void should_RejectOrders_when_OrdersAreNull() {
            assertThatNullPointerException().isThrownBy(() -> new Observation(
                    robotView(),
                    emptyView(),
                    emptyView(),
                    null,
                    0,
                    new Failures(1, 3),
                    new LoadingBayView(2, 4)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects null failures")
        void should_RejectFailures_when_FailuresAreNull() {
            assertThatNullPointerException().isThrownBy(() -> new Observation(
                    robotView(),
                    emptyView(),
                    emptyView(),
                    emptyView(),
                    0,
                    null,
                    new LoadingBayView(2, 4)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null loading bay")
        void should_RejectLoadingBay_when_LoadingBayIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Observation(
                    robotView(),
                    emptyView(),
                    emptyView(),
                    emptyView(),
                    0,
                    new Failures(1, 3),
                    null
            ));
        }
    }

    @Nested
    @DisplayName("update")
    class UpdateMethodTests {

        @Test
        @DisplayName("Replaces the observation state")
        void should_ReplaceState_when_NewStateIsSupplied() {
            var observation = new Observation(
                    robotView(),
                    emptyView(),
                    emptyView(),
                    emptyView(),
                    1,
                    new Failures(1, 3),
                    new LoadingBayView(2, 4)
            );
            var robot = robotView();
            ArrayView<ShelfView> shelves = emptyView();
            ArrayView<JobView> jobs = emptyView();
            ArrayView<OrderView> orders = emptyView();
            var failures = new Failures(2, 4);
            var loadingBay = new LoadingBayView(3, 5);

            observation.update(robot, shelves, jobs, orders, 42, failures, loadingBay);

            assertThat(observation.robot()).isSameAs(robot);
            assertThat(observation.shelves()).isSameAs(shelves);
            assertThat(observation.jobs()).isSameAs(jobs);
            assertThat(observation.orders()).isSameAs(orders);
            assertThat(observation.currentTick()).isEqualTo(42);
            assertThat(observation.failures()).isSameAs(failures);
            assertThat(observation.loadingBay()).isSameAs(loadingBay);
        }
    }

    private static RobotView robotView() {
        return new RobotView(
                new GridPos(1, 2),
                new RobotBattery(8, 10),
                null,
                null,
                null
        );
    }

    private static <T> ArrayView<T> emptyView() {
        return GdxCollections.viewOf(new Array<>());
    }
}
