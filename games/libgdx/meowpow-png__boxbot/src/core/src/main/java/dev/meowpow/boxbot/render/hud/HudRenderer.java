package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;
import dev.meowpow.boxbot.render.assets.BakedFont;
import dev.meowpow.boxbot.render.assets.HudIcons;

import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Disposable;

import java.util.Objects;

/**
 * Draws HUD elements and components.
 */
@HotPath
public final class HudRenderer implements Disposable {

    private static final int PANEL_COUNT = HudPanels.values().length;
    private static final float PANEL_GAP_BASE = 8f;

    private static final float PANEL_BORDER_THICKNESS = 2f;
    private static final float PANEL_DIVIDER_THICKNESS = 1f;

    private final OrthographicCamera camera = new OrthographicCamera();
    private final HudViewport viewport = new HudViewport(camera);
    private final ShapeRenderer shapeRenderer = new ShapeRenderer();
    private final SpriteBatch batch = new SpriteBatch();

    private final Rectangle localBounds = new Rectangle();
    private final Vector2 unprojected = new Vector2();
    private final HudPanelBase[] panels = new HudPanelBase[PANEL_COUNT];

    private final HudLayout layout;

    /**
     * Creates a HUD renderer that draws text
     * with the given fonts, at the given scale.
     *
     * @param labelFontHeader the font used for panel header text
     * @param labelFontBody the font used for panel body text
     * @param scale the integer pixel scale to draw panel spacing and content at
     * @param failureLimit the number of shipment failures that ends the run
     * @param secondsPerTick simulation tick represented in real seconds
     * @param deliveryTimerTicks ticks allotted to ship an outbound order
     * @param orderWarningThresholdPercent remaining order lifetime at which warning state begins
     * @param orderCriticalThresholdPercent remaining order lifetime at which critical state begins
     * @param hudIcons icons intended to be rendered in HUD
     *
     * @throws NullPointerException if {@code headerFont}, {@code bodyFont} or {@code hudIcons} is null
     * @throws IllegalArgumentException if {@code scale} is not positive
     */
    public HudRenderer(
            BakedFont labelFontHeader,
            BakedFont labelFontBody,
            int scale,
            int failureLimit,
            float secondsPerTick,
            int deliveryTimerTicks,
            double orderWarningThresholdPercent,
            double orderCriticalThresholdPercent,
            HudIcons hudIcons
    ) {
        Objects.requireNonNull(labelFontHeader, "headerFont must not be null");
        Objects.requireNonNull(labelFontBody, "bodyFont must not be null");

        this.layout = new HudLayout(PANEL_COUNT, PANEL_GAP_BASE * scale);

        var fonts = new HudFonts(labelFontHeader.font(), labelFontBody.font());
        var frame = new HudPanelFrame(
                RenderColors.HUD_PANEL_FILL,
                RenderColors.HUD_PANEL_BORDER,
                PANEL_BORDER_THICKNESS,
                PANEL_DIVIDER_THICKNESS,
                scale
        );
        panels[HudPanels.STATUS_PANEL.index] = new StatusPanel(frame, fonts, scale, failureLimit);
        panels[HudPanels.ROBOT_PANEL.index] = new RobotPanel(frame, fonts, scale);
        panels[HudPanels.WAREHOUSE_PANEL.index] = new WarehousePanel(frame, fonts, scale);
        panels[HudPanels.SHIPMENT_PANEL.index] = new ShipmentPanel(
                frame,
                fonts,
                scale,
                secondsPerTick,
                hudIcons
        );
        panels[HudPanels.ORDERS_PANEL.index] = new OrdersPanel(
                frame,
                fonts,
                scale,
                secondsPerTick,
                deliveryTimerTicks,
                orderWarningThresholdPercent,
                orderCriticalThresholdPercent
        );
    }

    /**
     * Scrolls the orders panel's content by {@code delta}.
     *
     * @param delta the amount to scroll by, in world units
     */
    public void scrollOrders(float delta) {
        panels[HudPanels.ORDERS_PANEL.index].scroll(delta);
    }

    /**
     * Returns whether the given screen-space
     * point falls within the given panel's bounds.
     *
     * @param panel the panel to test
     * @param screenX the point's x coordinate, in screen pixels
     * @param screenY the point's y coordinate, in screen pixels
     */
    public boolean isMouseOverPanel(HudPanels panel, int screenX, int screenY) {
        unprojected.set(screenX, screenY);
        viewport.unproject(unprojected);
        return layout.panelBounds(panel.index).contains(unprojected);
    }

    /**
     * Returns whether the given screen-space point
     * falls within the shipment panel's depart-now icon.
     *
     * @param screenX the point's x coordinate, in screen pixels
     * @param screenY the point's y coordinate, in screen pixels
     */
    public boolean isMouseOverDepartIcon(int screenX, int screenY) {
        unprojected.set(screenX, screenY);
        viewport.unproject(unprojected);
        var shipmentPanel = (ShipmentPanel) panels[HudPanels.SHIPMENT_PANEL.index];
        return shipmentPanel.departIconBounds().contains(unprojected);
    }

    /**
     * Updates the viewport for the given screen bounds.
     *
     * @param bounds the HUD's screen bounds, in pixels
     */
    public void resize(Rectangle bounds) {
        viewport.setWorldSize(bounds.width, bounds.height);
        viewport.setScreenBounds(bounds);
        viewport.apply(true);

        localBounds.set(0, 0, bounds.width, bounds.height);
        layout.update(localBounds);
    }

    /**
     * Refreshes every panel from the
     * given simulation state and draws them.
     *
     * @param state the simulation state to read from
     */
    public void render(HudState state) {
        for (int i = 0; i < PANEL_COUNT; i++) {
            panels[i].update(state);
        }
        viewport.apply();

        shapeRenderer.setProjectionMatrix(camera.combined);
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        for (int i = 0; i < PANEL_COUNT; i++) {
            var slot = layout.panelBounds(i);
            panels[i].renderBars(shapeRenderer, slot.x, slot.y, slot.width, slot.height);
        }
        shapeRenderer.end();

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        for (int i = 0; i < PANEL_COUNT; i++) {
            var slot = layout.panelBounds(i);
            panels[i].renderText(batch, viewport, slot.x, slot.y, slot.width, slot.height);
        }
        batch.end();
    }

    @Override
    public void dispose() {
        shapeRenderer.dispose();
        batch.dispose();
    }
}
