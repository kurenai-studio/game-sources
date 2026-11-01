package dev.meowpow.boxbot.input.selection;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.engine.spatial.grid.TileSize;

import com.badlogic.gdx.math.Vector2;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Objects;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static org.assertj.core.api.Assertions.assertThat;

class SelectionControllerTest {

    private static final TileSize TILE_SIZE = new TileSize(10);

    @Nested
    @DisplayName("onClick")
    class OnClickMethodTests {

        @Test
        @DisplayName("Does not select bay as a destination when no matching order is open")
        void should_NotSelectBayDestination_when_NoMatchingOrderIsOpen() {
            var commands = new RecordingCommands(true);
            var controller = new SelectionController(commands, 1);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withLoadingBayCapacity(2)
                    .build();

            click(controller, world, 5, 5);
            click(controller, world, 15, 5);

            assertThat(controller.secondary()).isNull();
            assertThat(commands.destinations).isEmpty();
        }

        @Test
        @DisplayName("Ignores a second package click while the first pair's destination is still unpicked")
        void should_IgnoreSecondPackageClick_when_FirstPairDestinationStillUnpicked() {
            var commands = new RecordingCommands(true);
            var packages = List.of(PackageColor.BLUE, PackageColor.RED);
            var controller = new SelectionController(commands, 1);
            var world = world().withShelfPackages(packages).build();

            click(controller, world, 5, 5);

            var firstPrimary = controller.primary();
            click(controller, world, 15, 5);

            assertThat(controller.primary()).isEqualTo(firstPrimary);
            assertThat(controller.stagingPrimary()).isNull();
            assertThat(controller.queuedPairs().isEmpty()).isTrue();
            assertThat(commands.retrievals).isEqualTo(1);
        }

        @Test
        @DisplayName("Ignores a second package click after pickup but before a destination is picked")
        void should_IgnoreSecondPackageClick_when_CarriedPackageStillHasNoDestination() {
            var commands = new RecordingCommands(true);
            var packages = List.of(PackageColor.BLUE, PackageColor.RED);
            var controller = new SelectionController(commands, 1);
            var world = world().withShelfPackages(packages).build();

            var firstShelfId = world.shelves().get(0).id();
            click(controller, world, 5, 5);

            world.setShelfPackage(firstShelfId, null);
            controller.pruneStale(world);

            assertThat(controller.primary()).isNull();

            click(controller, world, 15, 5);

            assertThat(controller.stagingPrimary()).isNull();
            assertThat(controller.queuedPairs().isEmpty()).isTrue();
            assertThat(commands.retrievals).isEqualTo(1);
        }

        @Test
        @DisplayName("Does not redirect a carried package to the bay when no matching order is open")
        void should_NotRedirectCarriedPackageToBay_when_NoMatchingOrderIsOpen() {
            var commands = new RecordingCommands(true);
            var controller = new SelectionController(commands, 1);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE)
                    .withLoadingBayCapacity(2)
                    .build();

            var shelfId = world.shelves().get(0).id();

            click(controller, world, 5, 5);

            var pkg = world.shelves().get(0).occupyingPackage();

            world.setShelfPackage(shelfId, null);
            world.robot().pickUp(Objects.requireNonNull(pkg));
            controller.pruneStale(world);

            assertThat(controller.primary()).isNull();

            click(controller, world, 15, 5);

            assertThat(controller.secondary()).isNull();
            assertThat(commands.destinations).isEmpty();
        }
    }

    @Nested
    @DisplayName("resumeIfIdle")
    class ResumeIfIdleMethodTests {

        @Test
        @DisplayName("Discards a queued bay delivery when its matching order has expired")
        void should_DiscardQueuedBayDelivery_when_MatchingOrderHasExpired() {
            var commands = new RecordingCommands(false);
            var controller = new SelectionController(commands, 1);
            var world = world()
                    .withShelfPackage(PackageColor.BLUE).
                    withLoadingBayCapacity(2)
                    .build();

            var order = new OutboundOrder(
                    new OrderId(0),
                    PackageColor.BLUE,
                    100
            );
            click(controller, world, 5, 5);
            world.startOutboundOrder(order);

            click(controller, world, 15, 5);
            world.expireOutboundOrder(order);

            commands.idle = true;
            controller.resumeIfIdle(world);

            assertThat(controller.queuedPairs().isEmpty()).isTrue();
            assertThat(commands.retrievals).isZero();
            assertThat(commands.destinations).isEmpty();
        }
    }

    private static void click(SelectionController controller, World world, int x, int y) {
        controller.onClick(world, TILE_SIZE, new Vector2(x, y));
    }
}
