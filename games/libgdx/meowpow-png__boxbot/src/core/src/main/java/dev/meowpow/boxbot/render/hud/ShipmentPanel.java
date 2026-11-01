package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.assets.HudIcons;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The panel showing when the
 * truck is coming and what it's bringing.
 */
@HotPath
public final class ShipmentPanel extends HudPanelBase {

    private static final String TITLE = "SHIPMENT";
    private static final String STATUS_AT_BAY = "At bay";
    private static final String STATUS_EN_ROUTE = "En route";
    private static final String ETA_AT_BAY = "-";

    private static final float DEPART_ICON_SIZE_BASE = 12f;

    private static final int STATUS_ROW = 0;
    private static final int ETA_ROW = 1;
    private static final int MANIFEST_ROW = 2;

    private final float secondsPerTick;

    private final TextureRegion departIconActive;
    private final TextureRegion departIconInactive;
    private final Rectangle departIconBounds = new Rectangle();

    private final HudLabelValue status;
    private final HudText etaLabel;
    private final HudTimeText etaValue;

    private final HudText cargoLabel;
    private final HudPackageColorCounts packages;

    private boolean departAvailable;

    /**
     * Creates a new truck panel.
     *
     * @param frame the panel's background and border
     * @param fonts the fonts used for the header and labels/values
     * @param scale the integer pixel scale to draw spacing and content at
     * @param secondsPerTick simulation tick represented in real seconds
     * @param icons the icons for the depart-now control on the title line
     */
    public ShipmentPanel(
            HudPanelFrame frame,
            HudFonts fonts,
            int scale,
            float secondsPerTick,
            HudIcons icons
    ) {
        super(frame, fonts, TITLE, scale);
        this.secondsPerTick = secondsPerTick;
        this.departIconActive = icons.arrowRightActive();
        this.departIconInactive = icons.arrowRightInactive();

        status = labelValue("Status");
        etaLabel = bodyText(HudText.Alignment.LEFT);
        etaLabel.setText("ETA");
        etaValue = timeText();

        cargoLabel = bodyText(HudText.Alignment.LEFT);
        cargoLabel.setText("Cargo");
        packages = colorCounts();
    }

    /**
     * Refreshes this panel's content.
     *
     * @param state the simulation state to read truck state from
     */
    @Override
    public void update(HudState state) {
        var truck = state.truck();
        boolean visiting = truck.isVisiting();
        departAvailable = truck.canForceDepart();

        var statusContent = status.value().content();
        statusContent.setLength(0);
        statusContent.append(visiting ? STATUS_AT_BAY : STATUS_EN_ROUTE);

        var etaContent = etaValue.content();
        etaContent.setLength(0);
        if (visiting) {
            etaContent.append(ETA_AT_BAY);
        }
        else {
            int remaining = truck.ticksUntilNextVisit();
            float smoothTicksRemaining = Math.max(0f, remaining - state.alpha().value());
            int totalSeconds = Math.round(smoothTicksRemaining * secondsPerTick);
            appendTime(etaContent, totalSeconds);
        }
        int redCount = 0;
        int greenCount = 0;
        int blueCount = 0;

        var currentPackages = truck.cargo().current();
        for (int i = 0; i < currentPackages.size(); i++) {
            switch (currentPackages.get(i).color()) {
                case RED -> redCount++;
                case GREEN -> greenCount++;
                case BLUE -> blueCount++;
                case NONE -> {}
            }
        }
        this.packages.setCounts(redCount, greenCount, blueCount);
    }

    @Override
    protected void renderContentBars(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height
    ) {
        float rowTop = rowTop(y, height, STANDARD_ROW_COUNT, MANIFEST_ROW);
        float halfRowHeight = rowHeight(height, STANDARD_ROW_COUNT) / 2f;
        packages.renderSwatches(
                renderer,
                x + width - padding,
                rowTop - halfRowHeight
        );
    }

    @Override
    protected void renderHeaderIcon(
            SpriteBatch batch,
            float x,
            float y,
            float width,
            float height
    ) {
        float size = Math.round(DEPART_ICON_SIZE_BASE * scale);
        float iconX = Math.round(x + width - padding - size);
        float iconY = Math.round(headerCenterY(y, height) - size / 2f);

        departIconBounds.set(iconX, iconY, size, size);
        var icon = departAvailable ? departIconActive : departIconInactive;
        batch.draw(icon, iconX, iconY, size, size);
    }

    /**
     * Returns the depart-now icon's
     * last-rendered bounds, in world units.
     */
    public Rectangle departIconBounds() {
        return departIconBounds;
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
        row.set(x, y, width, height, STANDARD_ROW_COUNT);
        status.render(batch, row, STATUS_ROW);
        row.render(batch, ETA_ROW, etaLabel, etaValue);
        row.render(batch, MANIFEST_ROW, cargoLabel, packages);
    }
}
