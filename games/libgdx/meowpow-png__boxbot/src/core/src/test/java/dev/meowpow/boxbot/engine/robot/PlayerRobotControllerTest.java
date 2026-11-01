package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;
import dev.meowpow.boxbot.gdx.ArrayView;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.robot.RobotFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;
import static org.assertj.core.api.AssertionsForClassTypes.catchThrowable;

class PlayerRobotControllerTest {

    private final PlayerRobotController controller = new PlayerRobotController();

    @Nested
    @DisplayName("decide")
    class DecideMethodTests {

        @Test
        @DisplayName("Idles when nothing has been committed")
        void should_Idle_when_NothingCommitted() {
            var observation = idleObservation(100);

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Idle();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Retrieves the source shelf for a committed shelf retrieval")
        void should_Retrieve_when_ShelfRetrievalCommittedAndNotCarrying() {
            var observation = idleObservation(100);
            var sourceShelfId = new ShelfId(1);

            controller.commitRetrieveFromShelf(sourceShelfId);

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Retrieve(sourceShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles once carrying, holding the package until a destination is chosen")
        void should_Idle_when_ShelfRetrievalCommittedAndCarryingWithNoDestination() {
            controller.commitRetrieveFromShelf(new ShelfId(1));

            var actual = controller.decide(carryingObservation(JobType.RETRIEVAL));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Heads to the bay once carrying, when explicitly chosen as the destination")
        void should_GoToBay_when_ShelfRetrievalRedirectedToBayAndCarrying() {
            var observation = idleObservation(100);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(new RelocationDestination.Bay());
            controller.decide(observation);

            var actual = controller.decide(carryingObservationWithOrder(JobType.RETRIEVAL));
            assertThat(actual).isEqualTo(new ControllerDecision.GoToBay());
        }

        @Test
        @DisplayName("Stores at the closest empty shelf when no order matches a bay-bound package")
        void should_StoreAtClosestEmptyShelf_when_BayBoundPackageHasNoMatchingOrder() {
            var closestShelf = new ShelfView(
                    new ShelfId(2),
                    new GridPos(1, 0),
                    false,
                    null,
                    null
            );
            var fartherShelf = new ShelfView(
                    new ShelfId(3),
                    new GridPos(2, 0),
                    false,
                    null,
                    null
            );
            var robot = carryingRobot(JobType.RETRIEVAL, 100);
            var observation = new ObservationBuilder(robot)
                    .shelves(arrayViewOf(fartherShelf, closestShelf))
                    .build();

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(new RelocationDestination.Bay());

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.StoreAt(closestShelf.shelfId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles while carrying when no order matches bay-bound package and no empty shelf")
        void should_Idle_when_BayBoundPackageHasNoMatchingOrderAndNoShelfIsEmpty() {
            var occupiedShelf = new ShelfView(
                    new ShelfId(2),
                    new GridPos(1, 0),
                    true,
                    new PackageId(2),
                    PackageColor.BLUE
            );
            var robot = carryingRobot(JobType.RETRIEVAL, 100);
            var observation = new ObservationBuilder(robot)
                    .shelves(arrayViewOf(occupiedShelf))
                    .build();

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(new RelocationDestination.Bay());

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.Idle();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles once shipped to the bay, completing a shelf retrieval")
        void should_Idle_when_ShelfRetrievalShippedToBay() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.decide(idleObservation(100));
            controller.setDestination(new RelocationDestination.Bay());
            controller.decide(carryingObservationWithOrder(JobType.RETRIEVAL));

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Stores at the destination once carrying, when redirected to a shelf")
        void should_StoreAtDestination_when_ShelfRetrievalRedirectedAndCarrying() {
            var observation = idleObservation(100);
            var destinationShelfId = new ShelfId(2);
            var destination = new RelocationDestination.Shelf(destinationShelfId);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.decide(observation);

            var actual = controller.decide(carryingObservation(JobType.RETRIEVAL));
            var expected = new ControllerDecision.StoreAt(destinationShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles once delivered, completing a redirected shelf retrieval")
        void should_Idle_when_RedirectedShelfRetrievalDelivered() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.decide(idleObservation(100));
            controller.decide(carryingObservation(JobType.RETRIEVAL));

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Takes the matching job for a committed bay relocation")
        void should_TakeJob_when_BayRelocationCommittedAndNotCarrying() {
            var packageId = new PackageId(7);
            var destinationShelfId = new ShelfId(2);

            controller.commitRelocateFromBay(packageId, destinationShelfId);

            var robot = idleRobot(100);
            var matchingJob = job("putaway-1", packageId);
            var jobs = arrayViewOf(job("putaway-0", new PackageId(0)), matchingJob);
            var observation = observation(robot, jobs);

            var actual = controller.decide(observation);
            var expected = new ControllerDecision.TakeJob(matchingJob.jobId());

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Idles when no job matches a committed bay relocation")
        void should_Idle_when_BayRelocationHasNoMatchingJob() {
            controller.commitRelocateFromBay(
                    new PackageId(7),
                    new ShelfId(2)
            );
            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Stores at the destination once carrying, for a bay relocation")
        void should_StoreAtDestination_when_BayRelocationCommittedAndCarrying() {
            var destinationShelfId = new ShelfId(2);

            controller.commitRelocateFromBay(
                    new PackageId(7),
                    destinationShelfId
            );
            var actual = controller.decide(carryingObservationWithOrder(JobType.PUTAWAY));
            var expected = new ControllerDecision.StoreAt(destinationShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Heads to the bay once carrying, when a bay relocation is redirected to the bay")
        void should_GoToBay_when_BayRelocationRedirectedToBayAndCarrying() {
            controller.commitRelocateFromBay(new PackageId(7), new ShelfId(2));
            controller.setDestination(new RelocationDestination.Bay());

            var actual = controller.decide(carryingObservationWithOrder(JobType.PUTAWAY));
            assertThat(actual).isEqualTo(new ControllerDecision.GoToBay());
        }

        @Test
        @DisplayName("Charges when charging is committed and the battery isn't full")
        void should_Charge_when_ChargeCommittedAndBatteryNotFull() {
            controller.commitCharge();

            var actual = controller.decide(idleObservation(50));
            assertThat(actual).isEqualTo(new ControllerDecision.Charge());
        }

        @Test
        @DisplayName("Idles when charging is committed but the battery is already full")
        void should_Idle_when_ChargeCommittedAndBatteryFull() {
            controller.commitCharge();

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Idles once the battery fills up, completing a charge command")
        void should_Idle_when_ChargeCompletes() {
            controller.commitCharge();
            controller.decide(idleObservation(50));

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Charges while carrying, when charging is requested and the battery isn't full")
        void should_Charge_when_CarryingAndChargeRequestedAndBatteryNotFull() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.decide(carryingObservation(100));
            controller.commitCharge();

            var actual = controller.decide(carryingObservation(50));
            assertThat(actual).isEqualTo(new ControllerDecision.Charge());
        }

        @Test
        @DisplayName("Resumes delivery to the chosen destination once a mid-carry charge completes")
        void should_ResumeDelivery_when_ChargeCompletesWhileCarrying() {
            var destinationShelfId = new ShelfId(2);
            var destination = new RelocationDestination.Shelf(destinationShelfId);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.decide(carryingObservation(100));
            controller.commitCharge();
            controller.decide(carryingObservation(50));

            var actual = controller.decide(carryingObservation(100));
            var expected = new ControllerDecision.StoreAt(destinationShelfId);

            assertThat(actual).isEqualTo(expected);
        }
    }

    @Nested
    @DisplayName("commit")
    class CommitTests {

        @Test
        @DisplayName("Retargets to a new shelf retrieval while the previous pickup hasn't been retrieved")
        void should_RetargetCommand_when_PreviousPickupNotYetRetrieved() {
            var newSource = new ShelfId(3);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.commitRetrieveFromShelf(newSource);

            var actual = controller.decide(idleObservation(100));
            var expected = new ControllerDecision.Retrieve(newSource);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Retargets to a new bay relocation while the previous pickup hasn't been retrieved")
        void should_RetargetCommand_when_PreviousPickupNotYetRetrievedForBayRelocation() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.commitRelocateFromBay(
                    new PackageId(7),
                    new ShelfId(3)
            );
            var actual = controller.decide(idleObservation(100));
            var expected = new ControllerDecision.Idle();

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Ignores charging while the previous pickup hasn't been retrieved")
        void should_IgnoreCharge_when_PreviousPickupNotYetRetrieved() {
            var sourceShelfId = new ShelfId(1);

            controller.commitRetrieveFromShelf(sourceShelfId);
            controller.commitCharge();

            var actual = controller.decide(idleObservation(50));
            var expected = new ControllerDecision.Retrieve(sourceShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Ignores a new command once the package has already been picked up")
        void should_IgnoreNewCommand_when_PackageAlreadyRetrieved() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.decide(carryingObservation(JobType.RETRIEVAL));

            controller.commitRetrieveFromShelf(new ShelfId(3));

            assertThat(controller.requestedSource()).isNull();
        }

        @Test
        @DisplayName("Merges a charge request into the relocation once the package is carried")
        void should_MergeChargeRequest_when_PackageAlreadyRetrieved() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.decide(carryingObservation(JobType.RETRIEVAL));

            controller.commitCharge();

            assertThat(controller.chargingRequested()).isTrue();
            assertThat(controller.isRelocating()).isTrue();
            assertThat(controller.requestedRedirect()).isEqualTo(destination);
        }

        @Test
        @DisplayName("Ignores a charge command while the package hasn't been picked up yet")
        void should_IgnoreChargeCommand_when_PackageNotYetRetrieved() {
            var sourceShelfId = new ShelfId(1);

            controller.commitRetrieveFromShelf(sourceShelfId);
            controller.commitCharge();

            assertThat(controller.chargingRequested()).isFalse();
            assertThat(controller.requestedSource()).isEqualTo(new JobSource.Shelf(sourceShelfId));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null source shelf")
        void should_RejectSourceShelfId_when_SourceShelfIdIsNull() {
            var thrown = catchThrowable(() ->
                    controller.commitRetrieveFromShelf(null)
            );
            assertThat(thrown).isInstanceOf(NullPointerException.class);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null package id")
        void should_RejectPackageId_when_PackageIdIsNull() {
            var thrown = catchThrowable(() -> controller.commitRelocateFromBay(
                    null,
                    new ShelfId(1)
            ));
            assertThat(thrown).isInstanceOf(NullPointerException.class);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null destination shelf, for a bay relocation")
        void should_RejectDestinationShelfId_when_DestinationShelfIdIsNullForBayRelocation() {
            var thrown = catchThrowable(() -> controller.commitRelocateFromBay(
                    new PackageId(7),
                    null
            ));
            assertThat(thrown).isInstanceOf(NullPointerException.class);
        }
    }

    @Nested
    @DisplayName("setDestination")
    class SetDestinationMethodTests {

        @Test
        @DisplayName("Redirects a pending shelf retrieval to the given shelf")
        void should_RedirectDestination_when_ShelfRetrievalPending() {
            var destinationShelfId = new ShelfId(2);
            var destination = new RelocationDestination.Shelf(destinationShelfId);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);

            var observation = carryingObservation(JobType.RETRIEVAL);
            var actual = controller.decide(observation);
            var expected = new ControllerDecision.StoreAt(destinationShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("No-ops when nothing is pending")
        void should_NoOp_when_NothingPending() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.setDestination(destination);

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Redirects a pending bay relocation to the given shelf")
        void should_RedirectDestination_when_BayRelocationPending() {
            var redirectedDestination = new ShelfId(3);
            var destination = new RelocationDestination.Shelf(redirectedDestination);

            controller.commitRelocateFromBay(
                    new PackageId(7), new ShelfId(2)
            );
            controller.setDestination(destination);

            var actual = controller.decide(carryingObservation(JobType.PUTAWAY));
            var expected = new ControllerDecision.StoreAt(redirectedDestination);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null destination")
        void should_RejectDestination_when_DestinationIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    controller.setDestination(null)
            );
        }

        @Test
        @DisplayName("Redirects a shelf retrieval already picked up, mid-transit to the bay")
        void should_RedirectDestination_when_ShelfRetrievalAlreadyCarrying() {
            var redirectedDestination = new ShelfId(2);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            var carrying = carryingObservation(JobType.RETRIEVAL);
            controller.decide(carrying);

            var destination = new RelocationDestination.Shelf(redirectedDestination);
            controller.setDestination(destination);

            var actual = controller.decide(carrying);
            var expected = new ControllerDecision.StoreAt(redirectedDestination);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Redirects a bay relocation already picked up, mid-transit to a shelf")
        void should_RedirectDestination_when_BayRelocationAlreadyCarrying() {
            var redirectedDestination = new ShelfId(3);

            controller.commitRelocateFromBay(
                    new PackageId(7),
                    new ShelfId(2)
            );
            var carrying = carryingObservation(JobType.PUTAWAY);
            controller.decide(carrying);

            var destination = new RelocationDestination.Shelf(redirectedDestination);
            controller.setDestination(destination);

            var actual = controller.decide(carrying);
            var expected = new ControllerDecision.StoreAt(redirectedDestination);

            assertThat(actual).isEqualTo(expected);
        }
    }

    @Nested
    @DisplayName("isRelocating")
    class IsRelocatingMethodTests {

        @Test
        @DisplayName("Returns false when nothing is pending")
        void should_ReturnFalse_when_NothingPending() {
            assertThat(controller.isRelocating()).isFalse();
        }

        @Test
        @DisplayName("Returns true when a shelf retrieval is pending")
        void should_ReturnTrue_when_ShelfRetrievalPending() {
            controller.commitRetrieveFromShelf(new ShelfId(1));

            assertThat(controller.isRelocating()).isTrue();
        }

        @Test
        @DisplayName("Returns true when a bay relocation is pending")
        void should_ReturnTrue_when_BayRelocationPending() {
            controller.commitRelocateFromBay(
                    new PackageId(7),
                    new ShelfId(2)
            );
            assertThat(controller.isRelocating()).isTrue();
        }

        @Test
        @DisplayName("Returns false when a charge is pending")
        void should_ReturnFalse_when_ChargePending() {
            controller.commitCharge();

            assertThat(controller.isRelocating()).isFalse();
        }

        @Test
        @DisplayName("Returns false once a relocation completes")
        void should_ReturnFalse_when_RelocationCompletes() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.decide(idleObservation(100));
            controller.decide(carryingObservation(JobType.RETRIEVAL));
            controller.decide(idleObservation(100));

            assertThat(controller.isRelocating()).isFalse();
        }
    }

    @Nested
    @DisplayName("requestedRedirect")
    class RequestedRedirectMethodTests {

        @Test
        @DisplayName("Returns null when nothing is pending")
        void should_ReturnNull_when_NothingPending() {
            assertThat(controller.requestedRedirect()).isNull();
        }

        @Test
        @DisplayName("Returns null when a charge is pending")
        void should_ReturnNull_when_ChargePending() {
            controller.commitCharge();

            assertThat(controller.requestedRedirect()).isNull();
        }

        @Test
        @DisplayName("Returns null for a shelf retrieval with no destination set")
        void should_ReturnNull_when_ShelfRetrievalHasNoDestination() {
            controller.commitRetrieveFromShelf(new ShelfId(1));

            assertThat(controller.requestedRedirect()).isNull();
        }

        @Test
        @DisplayName("Returns the destination shelf for a redirected shelf retrieval")
        void should_ReturnDestination_when_ShelfRetrievalRedirected() {
            var destinationShelfId = new ShelfId(2);

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(new RelocationDestination.Shelf(destinationShelfId));

            var actual = controller.requestedRedirect();
            var expected = new RelocationDestination.Shelf(destinationShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Returns the destination shelf for a bay relocation")
        void should_ReturnDestination_when_BayRelocationPending() {
            var destinationShelfId = new ShelfId(2);

            controller.commitRelocateFromBay(
                    new PackageId(7),
                    destinationShelfId
            );
            var actual = controller.requestedRedirect();
            var expected = new RelocationDestination.Shelf(destinationShelfId);

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Returns the bay once redirected there")
        void should_ReturnBay_when_RedirectedToBay() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(new RelocationDestination.Bay());

            var actual = controller.requestedRedirect();
            var expected = new RelocationDestination.Bay();

            assertThat(actual).isEqualTo(expected);
        }
    }

    @Nested
    @DisplayName("cancelDestination")
    class CancelDestinationMethodTests {

        @Test
        @DisplayName("Idles once carrying, after cancelling a shelf retrieval's destination")
        void should_Idle_when_ShelfRetrievalDestinationCancelledAndCarrying() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);

            controller.cancelDestination();

            var actual = controller.decide(carryingObservation(JobType.RETRIEVAL));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("Idles once carrying, after cancelling a bay relocation's destination")
        void should_Idle_when_BayRelocationDestinationCancelledAndCarrying() {
            controller.commitRelocateFromBay(
                    new PackageId(7),
                    new ShelfId(2)
            );
            controller.cancelDestination();

            var actual = controller.decide(carryingObservation(JobType.PUTAWAY));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("No-ops when nothing is pending")
        void should_NoOp_when_NothingPending() {
            controller.cancelDestination();

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }

        @Test
        @DisplayName("No-ops when a charge is pending")
        void should_NoOp_when_ChargePending() {
            controller.commitCharge();
            controller.cancelDestination();

            var actual = controller.decide(idleObservation(50));
            assertThat(actual).isEqualTo(new ControllerDecision.Charge());
        }
    }

    @Nested
    @DisplayName("cancelRequested")
    class CancelRequestedMethodTests {

        @Test
        @DisplayName("Returns false when nothing is pending")
        void should_ReturnFalse_when_NothingPending() {
            assertThat(controller.cancelRequested()).isFalse();
        }

        @Test
        @DisplayName("Returns false when a charge is pending")
        void should_ReturnFalse_when_ChargePending() {
            controller.commitCharge();

            assertThat(controller.cancelRequested()).isFalse();
        }

        @Test
        @DisplayName("Returns false for a shelf retrieval with a destination chosen")
        void should_ReturnFalse_when_ShelfRetrievalHasDestination() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);

            assertThat(controller.cancelRequested()).isFalse();
        }

        @Test
        @DisplayName("Returns true for a shelf retrieval with its destination cancelled")
        void should_ReturnTrue_when_ShelfRetrievalDestinationCancelled() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.cancelDestination();

            assertThat(controller.cancelRequested()).isTrue();
        }

        @Test
        @DisplayName("Returns true for a bay relocation with its destination cancelled")
        void should_ReturnTrue_when_BayRelocationDestinationCancelled() {
            controller.commitRelocateFromBay(
                    new PackageId(7),
                    new ShelfId(2)
            );
            controller.cancelDestination();

            assertThat(controller.cancelRequested()).isTrue();
        }
    }

    @Nested
    @DisplayName("cancelPickup")
    class CancelPickupMethodTests {

        @Test
        @DisplayName("Idles a shelf retrieval that hasn't been picked up yet")
        void should_Idle_when_ShelfRetrievalNotYetCarried() {
            controller.commitRetrieveFromShelf(new ShelfId(1));

            controller.cancelPickup();

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
            assertThat(controller.isRelocating()).isFalse();
        }

        @Test
        @DisplayName("Idles a bay relocation that hasn't been picked up yet")
        void should_Idle_when_BayRelocationNotYetCarried() {
            controller.commitRelocateFromBay(new PackageId(7), new ShelfId(2));

            controller.cancelPickup();

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
            assertThat(controller.isRelocating()).isFalse();
        }

        @Test
        @DisplayName("No-ops once the package is already being carried")
        void should_NoOp_when_AlreadyCarrying() {
            var destination = new RelocationDestination.Shelf(new ShelfId(2));

            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.setDestination(destination);
            controller.decide(carryingObservation(JobType.RETRIEVAL));
            controller.cancelPickup();

            var actual = controller.decide(carryingObservation(JobType.RETRIEVAL));
            var expected = new ControllerDecision.StoreAt(new ShelfId(2));

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("No-ops when nothing is pending")
        void should_NoOp_when_NothingPending() {
            controller.cancelPickup();

            var actual = controller.decide(idleObservation(100));
            assertThat(actual).isEqualTo(new ControllerDecision.Idle());
        }
    }

    @Nested
    @DisplayName("pickupCancelled")
    class PickupCancelledMethodTests {

        @Test
        @DisplayName("Returns false when nothing is pending")
        void should_ReturnFalse_when_NothingPending() {
            assertThat(controller.pickupCancelled()).isFalse();
        }

        @Test
        @DisplayName("Returns false for a shelf retrieval not yet cancelled")
        void should_ReturnFalse_when_ShelfRetrievalNotCancelled() {
            controller.commitRetrieveFromShelf(new ShelfId(1));

            assertThat(controller.pickupCancelled()).isFalse();
        }

        @Test
        @DisplayName("Returns true once a pickup is cancelled")
        void should_ReturnTrue_when_PickupCancelled() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.cancelPickup();

            assertThat(controller.pickupCancelled()).isTrue();
        }

        @Test
        @DisplayName("Resets once a new command is committed")
        void should_Reset_when_NewCommandCommitted() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.cancelPickup();
            controller.decide(idleObservation(100));
            controller.commitRetrieveFromShelf(new ShelfId(2));

            assertThat(controller.pickupCancelled()).isFalse();
        }
    }

    @Nested
    @DisplayName("chargingRequested")
    class ChargingRequestedMethodTests {

        @Test
        @DisplayName("Returns false when nothing is pending")
        void should_ReturnFalse_when_NothingPending() {
            assertThat(controller.chargingRequested()).isFalse();
        }

        @Test
        @DisplayName("Returns false while a relocation is pending but not yet retrieved")
        void should_ReturnFalse_when_RelocationNotYetRetrieved() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.commitCharge();

            assertThat(controller.chargingRequested()).isFalse();
        }

        @Test
        @DisplayName("Returns true once charging is requested while carrying")
        void should_ReturnTrue_when_ChargeRequestedWhileCarrying() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.decide(carryingObservation(JobType.RETRIEVAL));

            controller.commitCharge();

            assertThat(controller.chargingRequested()).isTrue();
        }

        @Test
        @DisplayName("Returns false once the battery fills up, completing the charge")
        void should_ReturnFalse_when_ChargingCompletesWhileCarrying() {
            controller.commitRetrieveFromShelf(new ShelfId(1));
            controller.decide(carryingObservation(100));

            controller.commitCharge();

            controller.decide(carryingObservation(50));
            controller.decide(carryingObservation(100));

            assertThat(controller.chargingRequested()).isFalse();
        }
    }

    private static Observation idleObservation(int batteryLevel) {
        return observation(idleRobot(batteryLevel));
    }

    private static Observation carryingObservation(JobType jobType) {
        return observation(carryingRobot(jobType, 100));
    }

    private static Observation carryingObservationWithOrder(JobType jobType) {
        var order = new OrderView(new OrderId(0), PackageColor.RED, 100);
        return new ObservationBuilder(carryingRobot(jobType, 100))
                .orders(arrayViewOf(order))
                .build();
    }

    private static Observation carryingObservation(int batteryLevel) {
        return observation(carryingRobot(JobType.RETRIEVAL, batteryLevel));
    }

    private static Observation observation(RobotView robot) {
        return new ObservationBuilder(robot).build();
    }

    private static Observation observation(RobotView robot, ArrayView<JobView> jobs) {
        return new ObservationBuilder(robot).jobs(jobs).build();
    }
}
