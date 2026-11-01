package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.spatial.grid.GridFixtures;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.entity.PackageFixtures.packageWithId;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class ShelfTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null shelf id")
        void should_RejectShelfId_when_ShelfIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Shelf(
                            null,
                            GridFixtures.origin(),
                            "S1"
                    )
            );
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null position")
        void should_RejectPosition_when_PositionIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Shelf(
                            new ShelfId(1),
                            null,
                            "S1"
                    )
            );
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null label")
        void should_RejectLabel_when_LabelIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Shelf(
                            new ShelfId(1),
                            GridFixtures.origin(),
                            null
                    )
            );
        }
    }

    @Nested
    @DisplayName("position")
    class PositionMethodTests {

        @Test
        @DisplayName("Returns the shelf position")
        void should_ReturnPosition_when_Requested() {
            assertThat(shelf().position()).isEqualTo(GridFixtures.origin());
        }
    }

    @Nested
    @DisplayName("label")
    class LabelMethodTests {

        @Test
        @DisplayName("Returns the shelf label")
        void should_ReturnLabel_when_Requested() {
            assertThat(shelf().label()).isEqualTo("S1");
        }
    }

    @Nested
    @DisplayName("occupyingPackage")
    class OccupyingPackageMethodTests {

        private final Shelf shelf = shelf();

        @Test
        @DisplayName("Returns null for a newly created shelf")
        void should_ReturnNull_when_ShelfIsNew() {
            assertThat(shelf.occupyingPackage()).isNull();
        }
    }

    @Nested
    @DisplayName("setOccupyingPackage")
    class SetOccupyingPackageMethodTests {

        private final Shelf shelf = shelf();

        @Test
        @DisplayName("Stores the assigned package")
        void should_StorePackage_when_PackageIsAssigned() {
            var pkg = packageWithId(1);

            shelf.setOccupyingPackage(pkg);

            assertThat(shelf.occupyingPackage()).isEqualTo(pkg);
        }

        @Test
        @SuppressWarnings("ConstantValue")
        @DisplayName("Clears occupancy when assigned null")
        void should_ClearOccupancy_when_PackageIsNull() {
            shelf.setOccupyingPackage(packageWithId(1));
            shelf.setOccupyingPackage(null);

            assertThat(shelf.occupyingPackage()).isNull();
        }
    }

    private static Shelf shelf() {
        return new Shelf(new ShelfId(1), GridFixtures.origin(), "S1");
    }
}
