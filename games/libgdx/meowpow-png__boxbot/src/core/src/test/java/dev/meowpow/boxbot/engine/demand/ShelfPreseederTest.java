package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class ShelfPreseederTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a fraction below zero")
        void should_RejectFraction_when_FractionIsBelowZero() {
            assertThatIllegalArgumentException().isThrownBy(() -> shelfPreseeder(-0.1));
        }

        @Test
        @DisplayName("Rejects a fraction above one")
        void should_RejectFraction_when_FractionIsAboveOne() {
            assertThatIllegalArgumentException().isThrownBy(() -> shelfPreseeder(1.1));
        }
    }

    @Nested
    @DisplayName("preseed")
    class PreseedMethodTests {

        private final World world = world().withShelves(20).build();

        @Test
        @DisplayName("Occupies the rounded shelf count for a given fraction")
        void should_OccupyRoundedShelfCount_when_FractionIsApplied() {
            shelfPreseeder(0.25).preseed(world);

            assertThat(occupiedShelfIds(world)).hasSize(5);
        }

        @Test
        @DisplayName("Never selects the same shelf twice")
        void should_NotDuplicateSelection_when_Preseeding() {
            shelfPreseeder(0.5).preseed(world);

            var occupied = occupiedShelfIds(world);

            assertThat(occupied).hasSize(10);
            assertThat(occupied).doesNotHaveDuplicates();
        }

        @Test
        @DisplayName("Assigns unique package ids")
        void should_AssignUniquePackageIds_when_Preseeding() {
            shelfPreseeder(0.5).preseed(world);

            var ids = new ArrayList<PackageId>();
            var shelves = world.shelves();
            for (int i = 0; i < shelves.size(); i++) {
                var pkg = shelves.get(i).occupyingPackage();
                if (pkg != null) {
                    ids.add(pkg.id());
                }
            }

            assertThat(ids).doesNotHaveDuplicates();
        }

        @Test
        @DisplayName("Selects the same shelves when the seed is the same")
        void should_SelectSameShelves_when_SeedIsTheSame() {
            var otherWorld = world().withShelves(20).build();

            shelfPreseeder(42L, 0.25).preseed(world);
            shelfPreseeder(42L, 0.25).preseed(otherWorld);

            assertThat(occupiedShelfIds(world)).isEqualTo(occupiedShelfIds(otherWorld));
        }

        @Test
        @DisplayName("Leaves shelves untouched when the fraction is zero")
        void should_LeaveShelvesUntouched_when_FractionIsZero() {
            shelfPreseeder(0.0).preseed(world);

            assertThat(occupiedShelfIds(world)).isEmpty();
        }

        @Test
        @DisplayName("Occupies every shelf when the fraction is one")
        void should_OccupyEveryShelf_when_FractionIsOne() {
            shelfPreseeder(1.0).preseed(world);

            assertThat(occupiedShelfIds(world)).hasSize(20);
        }

        @Test
        @DisplayName("Assigns a colored package to every stocked shelf")
        void should_AssignColoredPackages_when_ShelvesAreStocked() {
            shelfPreseeder(0.5).preseed(world);

            var colors = new ArrayList<PackageColor>();
            var shelves = world.shelves();
            for (int i = 0; i < shelves.size(); i++) {
                var pkg = shelves.get(i).occupyingPackage();
                if (pkg != null) {
                    colors.add(pkg.color());
                }
            }

            assertThat(colors).doesNotContain(PackageColor.NONE);
        }
    }

    private static List<ShelfId> occupiedShelfIds(World world) {
        var ids = new ArrayList<ShelfId>();
        var shelves = world.shelves();
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            if (shelf.occupyingPackage() != null) {
                ids.add(shelf.id());
            }
        }
        return ids;
    }

    private static ShelfPreseeder shelfPreseeder(double fraction) {
        return shelfPreseeder(1L, fraction);
    }

    private static ShelfPreseeder shelfPreseeder(long seed, double fraction) {
        return new ShelfPreseeder(seed, new ColorDemand(seed), fraction);
    }
}
