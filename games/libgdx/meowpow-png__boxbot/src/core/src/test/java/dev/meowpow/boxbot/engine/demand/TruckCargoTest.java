package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;

import com.badlogic.gdx.utils.Array;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static org.assertj.core.api.Assertions.*;

class TruckCargoTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a non-positive capacity")
        void should_ThrowIllegalArgumentException_when_CapacityIsNotPositive() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TruckCargo(0, new Array<>())
            );
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TruckCargo(-1, new Array<>())
            );
        }

        @Test
        @DisplayName("Rejects outbound packages exceeding capacity")
        void should_ThrowIllegalArgumentException_when_OutboundPackagesExceedCapacity() {
            var outbound = Array.with(packageWithId(0), packageWithId(1));

            assertThatIllegalArgumentException().isThrownBy(() ->
                    new TruckCargo(1, outbound)
            );
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects null outbound packages")
        void should_ThrowNullPointerException_when_OutboundPackagesIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new TruckCargo(1, null)
            );
        }
    }

    @Nested
    @DisplayName("outbound")
    class OutboundMethodTests {

        @Test
        @DisplayName("Returns every outbound package in delivery order")
        void should_ReturnEveryPackage_when_CargoIsNonEmpty() {
            var first = packageWithId(0, PackageColor.RED);
            var second = packageWithId(1, PackageColor.BLUE);
            var cargo = new TruckCargo(2, Array.with(first, second));

            var packages = cargo.outbound();

            assertThat(packages.size()).isEqualTo(2);
            assertThat(packages.get(0)).isEqualTo(first);
            assertThat(packages.get(1)).isEqualTo(second);
        }

        @Test
        @DisplayName("Still shows delivered packages")
        void should_StillShowDeliveredPackages_when_PackagesAreDelivered() {
            var first = packageWithId(0, PackageColor.RED);
            var second = packageWithId(1, PackageColor.BLUE);
            var cargo = new TruckCargo(2, Array.with(first, second));

            cargo.markDelivered();

            var packages = cargo.outbound();

            assertThat(packages.size()).isEqualTo(2);
            assertThat(packages.get(0)).isEqualTo(first);
        }
    }

    @Nested
    @DisplayName("markDelivered")
    class MarkDeliveredMethodTests {

        @Test
        @DisplayName("Advances to the next undelivered package")
        void should_AdvanceToNextPackage_when_Called() {
            var first = packageWithId(0, PackageColor.RED);
            var second = packageWithId(1, PackageColor.BLUE);
            var cargo = new TruckCargo(2, Array.with(first, second));

            cargo.markDelivered();

            assertThat(cargo.peekNext()).isEqualTo(second);
        }

        @Test
        @DisplayName("Throws when there is no outbound package left")
        void should_ThrowIllegalStateException_when_OutboundIsEmpty() {
            var cargo = new TruckCargo(1, new Array<>());

            assertThatIllegalStateException().isThrownBy(cargo::markDelivered);
        }
    }

    @Nested
    @DisplayName("hasRoom")
    class HasRoomMethodTests {

        @Test
        @DisplayName("Returns true when held packages are below capacity")
        void should_ReturnTrue_when_HeldIsBelowCapacity() {
            var cargo = new TruckCargo(2, Array.with(packageWithId(0)));

            assertThat(cargo.hasRoom()).isTrue();
        }

        @Test
        @DisplayName("Returns false once outbound and picked-up packages fill capacity")
        void should_ReturnFalse_when_CapacityIsFilled() {
            var cargo = new TruckCargo(2, Array.with(packageWithId(0)));

            cargo.pickUp(packageWithId(1));

            assertThat(cargo.hasRoom()).isFalse();
        }

        @Test
        @DisplayName("Returns true again once a delivery frees room")
        void should_ReturnTrue_when_DeliveryFreesRoom() {
            var cargo = new TruckCargo(2, Array.with(packageWithId(0)));

            cargo.pickUp(packageWithId(1));
            cargo.markDelivered();

            assertThat(cargo.hasRoom()).isTrue();
        }
    }

    @Nested
    @DisplayName("pickUp")
    class PickUpMethodTests {

        @Test
        @DisplayName("Adds the package to the picked-up packages")
        void should_AddPackage_when_RoomIsAvailable() {
            var cargo = new TruckCargo(1, new Array<>());
            var pkg = packageWithId(0);

            cargo.pickUp(pkg);

            assertThat(cargo.inbound().size()).isEqualTo(1);
            assertThat(cargo.inbound().get(0)).isEqualTo(pkg);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null package")
        void should_ThrowNullPointerException_when_PackageIsNull() {
            var cargo = new TruckCargo(1, new Array<>());

            assertThatNullPointerException().isThrownBy(() -> cargo.pickUp(null));
        }

        @Test
        @DisplayName("Throws when cargo has no room")
        void should_ThrowIllegalStateException_when_CargoIsFull() {
            var cargo = new TruckCargo(1, new Array<>());
            cargo.pickUp(packageWithId(0));

            assertThatIllegalStateException().isThrownBy(() ->
                    cargo.pickUp(packageWithId(1))
            );
        }
    }
}
