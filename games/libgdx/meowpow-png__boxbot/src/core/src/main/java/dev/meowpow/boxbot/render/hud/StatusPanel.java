package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The panel showing how the run is going.
 */
@HotPath
public final class StatusPanel extends HudPanelBase {

    private static final String TITLE = "STATUS";

    private static final int SCORE_ROW = 0;
    private static final int FAILED_ROW = 1;
    private static final int TIME_ROW = 2;

    private final int failureLimit;

    private final HudLabelValue score;
    private final HudLabelValue failed;
    private final HudText timeLabel;
    private final HudTimeText timeValue;

    /**
     * Creates a new status panel.
     *
     * @param frame the panel's background and border
     * @param fonts the fonts used for the header and labels/values
     * @param scale the integer pixel scale to draw spacing and content at
     * @param failureLimit the number of shipment failures that ends the run
     */
    public StatusPanel(HudPanelFrame frame, HudFonts fonts, int scale, int failureLimit) {
        super(frame, fonts, TITLE, scale);
        this.failureLimit = failureLimit;

        score = labelValue("Score");
        failed = labelValue("Failed");
        timeLabel = bodyText(HudText.Alignment.LEFT);
        timeLabel.setText("Time");
        timeValue = timeText();
    }

    /**
     * Refreshes this panel's content.
     *
     * @param state the simulation state to read run state from
     */
    @Override
    public void update(HudState state) {
        var world = state.world();
        var scoreContent = score.value().content();
        scoreContent.setLength(0);
        scoreContent.append(world.score());

        var failedContent = failed.value().content();
        failedContent.setLength(0);
        failedContent.append(world.shipmentFailures()).append(" / ").append(failureLimit);

        var timeContent = timeValue.content();
        timeContent.setLength(0);
        appendTime(timeContent, (int) world.elapsedSeconds());
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
        score.render(batch, row, SCORE_ROW);
        failed.render(batch, row, FAILED_ROW);
        row.render(batch, TIME_ROW, timeLabel, timeValue);
    }
}
