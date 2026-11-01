package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.World;
import dev.meowpow.boxbot.engine.entity.OrderId;
import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.logging.GameLog;
import dev.meowpow.boxbot.logging.LogTag;

import java.util.Objects;

/**
 * Generates scheduled outbound orders from the demand model.
 */
@HotPath
public final class OutboundOrderGenerator {

    private final ColorDemand colorDemand;
    private final DemandPlanner demandPlanner;

    private final int deliveryTimerTicks;

    private int nextOrderId;
    private int nextArrivalTick;

    /**
     * Creates an outbound order generator.
     *
     * @param colorDemand color demand distribution sampled for each order
     * @param demandPlanner sets the interval between order arrivals
     * @param deliveryTimerTicks ticks allowed to ship each order
     *
     * @throws NullPointerException if {@code colorDemand} or {@code demandPlanner} is null
     */
    public OutboundOrderGenerator(
            ColorDemand colorDemand,
            DemandPlanner demandPlanner,
            int deliveryTimerTicks
    ) {
        Objects.requireNonNull(colorDemand, "colorDemand must not be null");
        Objects.requireNonNull(demandPlanner, "demandPlanner must not be null");

        this.colorDemand = colorDemand;
        this.demandPlanner = demandPlanner;
        this.deliveryTimerTicks = deliveryTimerTicks;
        this.nextArrivalTick = demandPlanner.orderIntervalAt(0);
    }

    /**
     * Advances the generator by one tick.
     */
    public void tick(World world) {
        int currentTick = world.currentTick();
        if (currentTick < nextArrivalTick) {
            return;
        }
        var wantedColor = colorDemand.sample();
        var deadlineTick = currentTick + deliveryTimerTicks;
        var order = new OutboundOrder(nextOrderId(), wantedColor, deadlineTick);

        world.startOutboundOrder(order);
        nextArrivalTick = currentTick + demandPlanner.orderIntervalAt(currentTick);

        GameLog.infof(
                LogTag.DEMAND,
                "Order %s started, wants %s, due by tick %d",
                order.id(),
                wantedColor,
                deadlineTick
        );
    }

    private OrderId nextOrderId() {
        return new OrderId(nextOrderId++);
    }
}
