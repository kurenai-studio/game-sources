package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.robot.Robot;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The panel showing what the robot is doing right now.
 */
@HotPath
public final class RobotPanel extends HudPanelBase {

    private static final String TITLE = "ROBOT";

    private static final int BATTERY_SEGMENTS = 10;
    private static final float BATTERY_SEGMENT_GAP = 2f;
    private static final float BATTERY_BAR_X_OFFSET_BASE = 60f;
    private static final float BATTERY_LABEL_HEIGHT_FRACTION = 0.4f;
    private static final float BATTERY_BAR_HEIGHT_FRACTION = 0.5f;

    private static final int BATTERY_ROW = 0;
    private static final int CARGO_ROW = 1;
    private static final int STATE_ROW = 2;

    private final HudText batteryLabel;
    private final HudBar batteryBar;
    private final HudText cargoLabel;
    private final HudPackageColorText cargoValue;
    private final HudLabelValue robotState;

    private float batteryFill;

    /**
     * Creates a new robot panel.
     *
     * @param frame the panel's background and border
     * @param fonts the fonts used for the header and labels/values
     * @param scale the integer pixel scale to draw spacing and content at
     */
    public RobotPanel(HudPanelFrame frame, HudFonts fonts, int scale) {
        super(frame, fonts, TITLE, scale);

        batteryLabel = bodyText(HudText.Alignment.LEFT);
        batteryLabel.setText("Battery");

        batteryBar = new HudBar(
                RenderColors.BATTERY_FILL,
                RenderColors.BATTERY_TRACK,
                BATTERY_SEGMENTS,
                BATTERY_SEGMENT_GAP
        );
        cargoLabel = bodyText(HudText.Alignment.LEFT);
        cargoLabel.setText("Cargo");

        cargoValue = packageColorText(HudText.Alignment.RIGHT);
        robotState = labelValue("State");
    }

    /**
     * Refreshes this panel's content.
     *
     * @param state the simulation state to read robot state from
     */
    @Override
    public void update(HudState state) {
        var robot = state.world().robot();
        var battery = robot.battery();

        batteryFill = battery.percentage() / 100f;

        var carried = robot.carriedPackage();
        var carriedColor = carried == null ? PackageColor.NONE : carried.color();
        cargoValue.setText(carriedColor, carried == null ? "-" : carried.color().name());

        robotState.value().setText(state(robot));
    }

    @Override
    protected void renderContentBars(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height
    ) {
        float rowHeight = rowHeight(height, STANDARD_ROW_COUNT);
        float barHeight = rowHeight * BATTERY_BAR_HEIGHT_FRACTION;
        float rowTop = rowTop(y, height, STANDARD_ROW_COUNT, BATTERY_ROW);
        float barTop = rowTop - rowHeight * BATTERY_LABEL_HEIGHT_FRACTION;
        float barXOffset = BATTERY_BAR_X_OFFSET_BASE * scale;

        batteryBar.render(
                renderer,
                x + barXOffset,
                barTop - barHeight,
                width - barXOffset - padding,
                barHeight,
                batteryFill
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
        row.set(x, y, width, height, STANDARD_ROW_COUNT);
        row.render(batch, BATTERY_ROW, batteryLabel);
        row.render(batch, CARGO_ROW, cargoLabel, cargoValue);
        robotState.render(batch, row, STATE_ROW);
    }

    private static String state(Robot robot) {
        return switch (robot.action()) {
            case IDLE -> "IDLE";
            case MOVING -> "TRAVELING";
            case PICKING_UP -> "PICKING UP";
            case DROPPING_OFF -> "DROPPING OFF";
            case CHARGING -> "CHARGING";
        };
    }
}
