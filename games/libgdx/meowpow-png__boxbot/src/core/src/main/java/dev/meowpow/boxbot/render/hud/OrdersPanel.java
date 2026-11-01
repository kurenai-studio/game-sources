package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.engine.entity.OutboundOrder;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The panel showing what work is waiting for the robot.
 */
@HotPath
public final class OrdersPanel extends HudPanelBase {

    private static final String TITLE = "ORDERS";

    private static final float SCROLLBAR_WIDTH_BASE = 2f;
    private static final float SCROLLBAR_RIGHT_INSET_BASE = 4f;

    private final float scrollbarWidth;
    private final float scrollbarRightInset;

    private final float secondsPerTick;
    private final int deliveryTimerTicks;

    private final double orderWarningThresholdPercent;
    private final double orderCriticalThresholdPercent;

    private final HudScrollList scrollList;
    private final HudPackageColorText colorText;
    private final HudTimeText etaText;

    private final HudRowRenderer rowRenderer = this::renderRow;
    private ArrayView<OutboundOrder> orders = GdxCollections.emptyView();

    private int currentTick;
    private float alpha;

    /**
     * Creates a new orders panel.
     *
     * @param frame the panel's background and border
     * @param fonts the fonts used for the header and order rows
     * @param scale the integer pixel scale to draw spacing and content at
     * @param secondsPerTick simulation tick represented in real seconds
     * @param deliveryTimerTicks ticks allotted to ship an outbound order
     * @param orderWarningThresholdPercent remaining order lifetime at which warning state begins
     * @param orderCriticalThresholdPercent remaining order lifetime at which critical state begins
     */
    public OrdersPanel(
            HudPanelFrame frame,
            HudFonts fonts,
            int scale,
            float secondsPerTick,
            int deliveryTimerTicks,
            double orderWarningThresholdPercent,
            double orderCriticalThresholdPercent
    ) {
        super(frame, fonts, TITLE, scale);
        this.secondsPerTick = secondsPerTick;
        this.deliveryTimerTicks = deliveryTimerTicks;
        this.orderWarningThresholdPercent = orderWarningThresholdPercent;
        this.orderCriticalThresholdPercent = orderCriticalThresholdPercent;

        this.scrollList = new HudScrollList(1f, rowGap);
        this.colorText = packageColorText(HudText.Alignment.LEFT);
        this.etaText = timeText();
        this.scrollbarWidth = SCROLLBAR_WIDTH_BASE * scale;
        this.scrollbarRightInset = SCROLLBAR_RIGHT_INSET_BASE * scale;
    }

    /**
     * Refreshes this panel's content.
     *
     * @param state the simulation state to read open orders from
     */
    @Override
    public void update(HudState state) {
        var world = state.world();
        orders = world.outboundOrders();
        currentTick = world.currentTick();
        alpha = state.alpha().value();
        scrollList.setRowCount(orders.size());
    }

    /**
     * Scrolls the order list by {@code delta}.
     *
     * @param delta the amount to scroll by, in world units
     */
    @Override
    public void scroll(float delta) {
        scrollList.scrollBy(delta);
    }

    @Override
    protected void renderContentBars(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height
    ) {
        scrollList.setRowHeight(rowHeight(height, STANDARD_ROW_COUNT));
        scrollList.renderScrollbar(
                renderer,
                RenderColors.SCROLLBAR,
                x + width - scrollbarRightInset,
                scrollbarWidth
        );
    }

    @Override
    protected void renderContentText(
            SpriteBatch batch,
            Viewport viewport,
            float x,
            float y,
            float width,
            float height
    ) {
        scrollList.render(
                batch,
                viewport,
                x,
                y + rowPadding,
                width,
                contentHeight(height),
                rowRenderer
        );
    }

    private void renderRow(
            SpriteBatch batch,
            int index,
            float x,
            float y,
            float width,
            float height
    ) {
        var order = orders.get(index);

        colorText.setText(order.color(), order.color().name());
        float centeredTop = y + height - (height - colorText.height()) / 2f;
        colorText.render(batch, x + padding, centeredTop);

        int ticksRemaining = Math.max(0, order.deadlineTick() - currentTick);
        float smoothTicksRemaining = Math.max(0f, ticksRemaining - alpha);
        int totalSeconds = Math.round(smoothTicksRemaining * secondsPerTick);

        etaText.setColor(etaColor(smoothTicksRemaining));
        var etaContent = etaText.content();
        etaContent.setLength(0);
        appendTime(etaContent, totalSeconds);
        etaText.render(batch, x + width - padding, centeredTop);
    }

    private Color etaColor(float ticksRemaining) {
        double remainingFraction = ticksRemaining / (double) deliveryTimerTicks;
        if (remainingFraction <= orderCriticalThresholdPercent) {
            return RenderColors.ORDER_CRITICAL;
        }
        if (remainingFraction <= orderWarningThresholdPercent) {
            return RenderColors.ORDER_WARNING;
        }
        return RenderColors.HUD_PANEL_BODY_FONT;
    }
}
