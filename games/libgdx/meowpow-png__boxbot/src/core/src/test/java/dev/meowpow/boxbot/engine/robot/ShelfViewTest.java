package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class ShelfViewTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Accepts an unoccupied shelf")
        void should_AcceptUnoccupiedShelf_when_PackageFieldsAreNull() {
            var shelfId = new ShelfId(4);
            var position = new GridPos(2, 3);

            var shelfView = new ShelfView(
                    shelfId,
                    position,
                    false,
                    null,
                    null
            );
            assertThat(shelfView.shelfId()).isEqualTo(shelfId);
            assertThat(shelfView.position()).isEqualTo(position);
            assertThat(shelfView.occupied()).isFalse();
            assertThat(shelfView.packageId()).isNull();
            assertThat(shelfView.color()).isNull();
        }

        @Test
        @DisplayName("Retains an occupying package and its color")
        void should_RetainPackageDetails_when_ShelfIsOccupied() {
            var shelfId = new ShelfId(4);
            var position = new GridPos(2, 3);
            var packageId = new PackageId(7);

            var shelfView = new ShelfView(
                    shelfId,
                    position,
                    true,
                    packageId,
                    PackageColor.RED
            );
            assertThat(shelfView.shelfId()).isEqualTo(shelfId);
            assertThat(shelfView.position()).isEqualTo(position);
            assertThat(shelfView.occupied()).isTrue();
            assertThat(shelfView.packageId()).isEqualTo(packageId);
            assertThat(shelfView.color()).isEqualTo(PackageColor.RED);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null shelf identifier")
        void should_RejectShelfId_when_ShelfIdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new ShelfView(
                    null,
                    new GridPos(2, 3),
                    false,
                    null,
                    null
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null position")
        void should_RejectPosition_when_PositionIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new ShelfView(
                    new ShelfId(4),
                    null,
                    false,
                    null,
                    null
            ));
        }

        @Test
        @DisplayName("Rejects an occupied shelf without a package")
        void should_RejectOccupiedShelf_when_PackageIdIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new ShelfView(
                    new ShelfId(4),
                    new GridPos(2, 3),
                    true,
                    null,
                    null
            ));
        }

        @Test
        @DisplayName("Rejects an unoccupied shelf with a package")
        void should_RejectUnoccupiedShelf_when_PackageIdIsPresent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new ShelfView(
                    new ShelfId(4),
                    new GridPos(2, 3),
                    false,
                    new PackageId(7),
                    PackageColor.RED
            ));
        }

        @Test
        @DisplayName("Rejects a color without a package")
        void should_RejectColor_when_PackageIdIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new ShelfView(
                    new ShelfId(4),
                    new GridPos(2, 3),
                    false,
                    null,
                    PackageColor.RED
            ));
        }

        @Test
        @DisplayName("Rejects a package without a color")
        void should_RejectPackageId_when_ColorIsAbsent() {
            assertThatIllegalArgumentException().isThrownBy(() -> new ShelfView(
                    new ShelfId(4),
                    new GridPos(2, 3),
                    true,
                    new PackageId(7),
                    null
            ));
        }
    }
}
