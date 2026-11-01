package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.config.DemandCycleConfig;
import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static dev.meowpow.boxbot.engine.TestWorldBuilder.world;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class OutboundOrderGeneratorTest {

    private static final long DEMAND_SEED = 42L;

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Rejects a non-positive base arrival interval")
        void should_RejectBaseArrivalInterval_when_ItIsNotPositive() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    outboundOrderGenerator(0, 5)
            );
        }
    }

    @Nested
    @DisplayName("tick")
    class TickMethodTests {

        @Test
        @DisplayName("Does not start an order before the arrival interval elapses")
        void should_NotStartOrder_when_ArrivalIntervalHasNotElapsed() {
            var world = world().build();
            var process = outboundOrderGenerator(2, 5);

            advance(process, world, 1);

            assertThat(world.outboundOrders().isEmpty()).isTrue();
        }

        @Test
        @DisplayName("Starts an order for the sampled color")
        void should_StartOrderWithSampledColor_when_ArrivalIntervalElapses() {
            var world = world().build();
            var process = outboundOrderGenerator(1, 5);

            advance(process, world, 1);

            var order = onlyOutboundOrder(world);
            assertThat(order.color()).isEqualTo(firstSample());
        }

        @Test
        @DisplayName("Sets the delivery deadline from the current tick")
        void should_SetDeadlineTick_when_OrderStarts() {
            var world = world().build();
            var process = outboundOrderGenerator(1, 5);

            advance(process, world, 1);

            var actual = onlyOutboundOrder(world).deadlineTick();
            var expected = world.currentTick() + 5;

            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Assigns sequential order ids across arrivals")
        void should_AssignSequentialOrderIds_when_ArrivalsOccur() {
            var world = world().build();
            var process = outboundOrderGenerator(1, 5);

            advance(process, world, 2);

            var orders = world.outboundOrders();
            assertThat(orders.size()).isEqualTo(2);
            assertThat(orders.get(0).id()).isEqualTo(new OrderId(0));
            assertThat(orders.get(1).id()).isEqualTo(new OrderId(1));
        }
    }

    @SuppressWarnings("SameParameterValue")
    private static OutboundOrderGenerator outboundOrderGenerator(
            int arrivalIntervalTicks,
            int deliveryTimerTicks
    ) {
        var cycleConfig = new DemandCycleConfig(
                2,
                1,
                1
        );
        var colorDemand = new ColorDemand(DEMAND_SEED);
        var demandPlanner = new DemandPlanner(
                arrivalIntervalTicks,
                cycleConfig
        );
        return new OutboundOrderGenerator(
                colorDemand,
                demandPlanner,
                deliveryTimerTicks
        );
    }

    private static void advance(OutboundOrderGenerator generator, World world, int ticks) {
        for (int i = 0; i < ticks; i++) {
            world.tick();
            generator.tick(world);
        }
    }

    private static OutboundOrder onlyOutboundOrder(World world) {
        return world.outboundOrders().first();
    }

    private static PackageColor firstSample() {
        return new ColorDemand(DEMAND_SEED).sample();
    }
}
