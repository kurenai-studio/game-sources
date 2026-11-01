package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static org.assertj.core.api.Assertions.assertThat;

class StorageQuotaTest {

    @Nested
    @DisplayName("targets")
    class TargetsMethodTests {

        @Test
        @DisplayName("Sums to total shelf capacity regardless of how demand shares round")
        void should_sumToShelfCapacity_when_sharesDontDivideEvenly() {
            for (long seed = 0; seed < 200; seed++) {
                for (int shelfCount = 1; shelfCount <= 20; shelfCount++) {
                    var quota = new StorageQuota(new ColorDemand(seed));
                    var world = world().withShelves(shelfCount).build();

                    var targets = quota.targets(world);
                    int sum = 0;
                    for (var color : PackageColor.colored()) {
                        sum += targets.get(color, 0);
                    }

                    assertThat(sum)
                            .as("seed=%d shelfCount=%d", seed, shelfCount)
                            .isEqualTo(shelfCount);
                }
            }
        }

        @Test
        @DisplayName("Never assigns a negative target")
        void should_neverAssignNegativeTarget_when_buildingTargets() {
            for (long seed = 0; seed < 50; seed++) {
                var quota = new StorageQuota(new ColorDemand(seed));
                var world = world().withShelves(7).build();

                var targets = quota.targets(world);
                for (var color : PackageColor.colored()) {
                    assertThat(targets.get(color, 0))
                            .as("seed=%d color=%s", seed, color)
                            .isGreaterThanOrEqualTo(0);
                }
            }
        }

        @Test
        @DisplayName("Never leaves a color at zero once shelf count reaches the color count")
        void should_giveEveryColorHeadroom_when_shelfCountReachesColorCount() {
            var colorCount = PackageColor.colored().size;

            for (long seed = 0; seed < 200; seed++) {
                for (int shelfCount = colorCount; shelfCount <= 20; shelfCount++) {
                    var quota = new StorageQuota(new ColorDemand(seed));
                    var world = world().withShelves(shelfCount).build();

                    var targets = quota.targets(world);
                    for (var color : PackageColor.colored()) {
                        assertThat(targets.get(color, 0))
                                .as("seed=%d shelfCount=%d color=%s", seed, shelfCount, color)
                                .isGreaterThan(0);
                    }
                }
            }
        }
    }
}
