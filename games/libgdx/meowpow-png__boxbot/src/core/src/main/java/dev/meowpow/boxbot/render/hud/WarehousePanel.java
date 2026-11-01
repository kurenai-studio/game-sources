package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The panel showing how full the warehouse is.
 */
@HotPath
public final class WarehousePanel extends HudPanelBase {

    private static final String TITLE = "WAREHOUSE";

    private static final int BAY_ROW = 0;
    private static final int SHELVES_ROW = 1;
    private static final int COLORS_ROW = 2;

    private final HudLabelValue bay;
    private final HudLabelValue shelves;
    private final HudText colorsLabel;
    private final HudPackageColorCounts colorsCounts;

    /**
     * Creates a new warehouse panel.
     *
     * @param frame the panel's background and border
     * @param fonts the fonts used for the header and labels/values
     * @param scale the integer pixel scale to draw spacing and content at
     */
    public WarehousePanel(HudPanelFrame frame, HudFonts fonts, int scale) {
        super(frame, fonts, TITLE, scale);

        bay = labelValue("Bay");
        shelves = labelValue("Shelves");

        colorsLabel = bodyText(HudText.Alignment.LEFT);
        colorsLabel.setText("Colors");
        colorsCounts = colorCounts();
    }

    /**
     * Refreshes this panel's content.
     *
     * @param state the simulation state to read warehouse state from
     */
    @Override
    public void update(HudState state) {
        var world = state.world();
        var bayState = world.loadingBay();
        var shelfList = world.shelves();
        var bayContent = bay.value().content();
        var tilesCurrent = bayState.totalTiles() - bayState.freeTiles();

        bayContent.setLength(0);
        bayContent.append(tilesCurrent).append(" / ").append(bayState.totalTiles());

        int occupied = 0;
        int redCount = 0;
        int greenCount = 0;
        int blueCount = 0;

        for (int i = 0; i < shelfList.size(); i++) {
            var pkg = shelfList.get(i).occupyingPackage();
            if (pkg == null) {
                continue;
            }
            occupied++;
            switch (pkg.color()) {
                case RED -> redCount++;
                case GREEN -> greenCount++;
                case BLUE -> blueCount++;
                case NONE -> {}
            }
        }
        var shelvesContent = shelves.value().content();

        shelvesContent.setLength(0);
        shelvesContent.append(occupied).append(" / ").append(shelfList.size());

        colorsCounts.setCounts(redCount, greenCount, blueCount);
    }

    @Override
    protected void renderContentBars(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height
    ) {
        float rowTop = rowTop(y, height, STANDARD_ROW_COUNT, COLORS_ROW);
        float halfRowHeight = rowHeight(height, STANDARD_ROW_COUNT) / 2f;
        colorsCounts.renderSwatches(
                renderer,
                x + width - padding,
                rowTop - halfRowHeight
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
        bay.render(batch, row, BAY_ROW);
        shelves.render(batch, row, SHELVES_ROW);
        row.render(batch, COLORS_ROW, colorsLabel, colorsCounts);
    }
}
