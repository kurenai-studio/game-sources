package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;

import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.Viewport;

import java.util.Objects;

/**
 * The common base every HUD panel is built on.
 */
@HotPath
public abstract class HudPanelBase {

    private static final float PADDING_BASE = 10f;
    private static final float HEADER_X_OFFSET_BASE = 10f;
    private static final float HEADER_Y_OFFSET_BASE = 9f;
    private static final float DIVIDER_OFFSET_BASE = 24f;
    private static final float ROW_PADDING_BASE = 12f;
    private static final float ROW_GAP_BASE = 4f;
    private static final int SECONDS_PER_MINUTE = 60;

    /**
     * The row count every fixed-row
     * panel divides its content area into.
     */
    protected static final int STANDARD_ROW_COUNT = 3;

    /**
     * Horizontal inset for header
     * and content text, in world units.
     */
    protected final float padding;

    /**
     * Vertical padding between the divider
     * and the row content area's top edge, in world units.
     */
    protected final float rowPadding;

    /**
     * Vertical gap between content rows, in world units.
     */
    protected final float rowGap;

    /**
     * The integer pixel scale this
     * panel's spacing and content are drawn at.
     */
    protected final int scale;

    protected final ContentRow row = new ContentRow();

    private final float headerXOffset;
    private final float headerYOffset;
    private final float dividerOffset;
    private final float contentTopOffset;

    private final HudPanelFrame frame;
    private final HudText header;
    private final BitmapFont bodyFont;

    /**
     * Creates a new HUD panel.
     *
     * @param frame the panel's background and border
     * @param fonts the fonts used for the header and body content
     * @param title the header text
     * @param scale the integer pixel scale to draw spacing and content at
     *
     * @throws NullPointerException if {@code frame} or {@code fonts} is null
     * @throws IllegalArgumentException if {@code scale} is not positive
     */
    protected HudPanelBase(HudPanelFrame frame, HudFonts fonts, String title, int scale) {
        this.frame = Objects.requireNonNull(frame, "frame must not be null");
        Objects.requireNonNull(fonts, "fonts must not be null");
        if (scale <= 0) {
            throw new IllegalArgumentException("scale must be positive: " + scale);
        }
        this.scale = scale;
        this.padding = PADDING_BASE * scale;
        this.headerXOffset = HEADER_X_OFFSET_BASE * scale;
        this.headerYOffset = HEADER_Y_OFFSET_BASE * scale;
        this.dividerOffset = DIVIDER_OFFSET_BASE * scale;
        this.rowPadding = ROW_PADDING_BASE * scale;
        this.rowGap = ROW_GAP_BASE * scale;
        this.contentTopOffset = dividerOffset + rowPadding;
        this.bodyFont = fonts.body();

        this.header = new HudText(
                fonts.header(),
                HudText.Alignment.LEFT,
                RenderColors.ACCENT
        );
        this.header.setText(title);
    }

    /**
     * Creates a label/value pair.
     *
     * @param labelText the label's fixed text
     */
    protected final HudLabelValue labelValue(String labelText) {
        return new HudLabelValue(bodyFont, labelText);
    }

    /**
     * Creates a single line of text
     * drawn with this panel's body font.
     *
     * @param align the horizontal alignment relative to draw position
     */
    protected final HudText bodyText(HudText.Alignment align) {
        return new HudText(bodyFont, align, RenderColors.HUD_PANEL_BODY_FONT);
    }

    /**
     * Creates a per-color package counts row,
     * drawn with this panel's body font.
     */
    protected final HudPackageColorCounts colorCounts() {
        return new HudPackageColorCounts(bodyFont);
    }

    /**
     * Creates a single line of text, tinted
     * according to whichever package color it names.
     *
     * @param align the horizontal alignment relative to draw position
     */
    protected final HudPackageColorText packageColorText(HudText.Alignment align) {
        return new HudPackageColorText(bodyFont, align);
    }

    /**
     * Creates a right-aligned time text, drawn with this
     * panel's body font, whose digits don't shift as they change.
     */
    protected final HudTimeText timeText() {
        return new HudTimeText(bodyFont, RenderColors.HUD_PANEL_BODY_FONT);
    }

    /**
     * Refreshes this panel's content
     * from the current simulation state.
     *
     * @param state the simulation state to read from
     */
    public abstract void update(HudState state);

    /**
     * Scrolls this panel's content by given delta
     * if it's scrollable. Does nothing for panels that aren't.
     *
     * @param delta the amount to scroll by, in world units
     */
    public void scroll(float delta) {}

    /**
     * Draws the panel's frame and
     * shape-based content at the given position.
     *
     * @param renderer the shape renderer to draw into
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     */
    public final void renderBars(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height
    ) {
        frame.render(renderer, x, y, width, height, dividerOffset);
        renderContentBars(renderer, x, y, width, height);
    }

    /**
     * Draws the panel's header and
     * text-based content at the given position.
     *
     * @param batch the batch to draw into
     * @param viewport the viewport the batch is projected with
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     */
    public final void renderText(
            SpriteBatch batch,
            Viewport viewport,
            float x,
            float y,
            float width,
            float height
    ) {
        header.render(batch, x + headerXOffset, y + height - headerYOffset);
        renderHeaderIcon(batch, x, y, width, height);
        renderContentText(batch, viewport, x, y, width, height);
    }

    /**
     * Draws this panel's icon-based
     * content on the header's line, if any.
     *
     * @param batch the batch to draw into
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     */
    protected void renderHeaderIcon(
            SpriteBatch batch,
            float x,
            float y,
            float width,
            float height
    ) {}

    /**
     * Returns the vertical center of the header line.
     *
     * @param y the panel's bottom edge, in world units
     * @param height the panel's height, in world units
     */
    protected final float headerCenterY(float y, float height) {
        return y + height - headerYOffset - header.height() / 2f;
    }

    /**
     * Draws this panel's shape-based content below the header.
     *
     * @param renderer the shape renderer to draw into
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     */
    protected void renderContentBars(
            ShapeRenderer renderer,
            float x,
            float y,
            float width,
            float height
    ) {}

    /**
     * Draws this panel's text-based content below the header.
     *
     * @param batch the batch to draw into
     * @param viewport the viewport the batch is projected with
     * @param x the panel's left edge, in world units
     * @param y the panel's bottom edge, in world units
     * @param width the panel's width, in world units
     * @param height the panel's height, in world units
     */
    protected void renderContentText(
            SpriteBatch batch,
            Viewport viewport,
            float x,
            float y,
            float width,
            float height
    ) {}

    /**
     * Returns the height of one content row.
     *
     * @param height the panel's height, in world units
     * @param rowCount the number of rows to divide the content area into
     */
    protected final float rowHeight(float height, int rowCount) {
        float totalGap = rowGap * (rowCount - 1);
        return (height - contentTopOffset - rowPadding - totalGap) / rowCount;
    }

    /**
     * Returns the top of the given content row.
     * <p>
     * <strong>Implementation Note:</strong>
     * {@link ShapeRenderer} draws upward from
     * bottom-left {@code y}, so shape-based content
     * must subtract its own height from this value.
     *
     * @param y the panel's bottom edge, in world units
     * @param height the panel's height, in world units
     * @param rowCount the number of rows to divide the content area into
     * @param rowIndex the row's index, counting top to bottom from zero
     */
    protected final float rowTop(float y, float height, int rowCount, int rowIndex) {
        float rowHeight = rowHeight(height, rowCount);
        return y + height - contentTopOffset - rowIndex * (rowHeight + rowGap);
    }

    /**
     * Returns the height of the row content area.
     *
     * @param height the panel's height, in world units
     */
    protected final float contentHeight(float height) {
        return height - contentTopOffset - rowPadding;
    }

    /**
     * Appends total seconds to the given
     * builder as zero-padded {@code mm:ss}.
     *
     * @param builder the buffer to append to
     * @param totalSeconds the duration to format, in seconds
     */
    protected static void appendTime(StringBuilder builder, int totalSeconds) {
        int minutes = totalSeconds / SECONDS_PER_MINUTE;
        int seconds = totalSeconds % SECONDS_PER_MINUTE;

        appendPadded(builder, minutes);
        builder.append(':');
        appendPadded(builder, seconds);
    }

    private static void appendPadded(StringBuilder builder, int value) {
        if (value < 10) {
            builder.append('0');
        }
        builder.append(value);
    }

    /**
     * A panel's content row grid.
     */
    protected final class ContentRow {

        private float x;
        private float width;
        private float top;
        private float rowHeight;

        /**
         * Configures this row grid for
         * the given panel bounds and row count.
         *
         * @param x the panel's left edge, in world units
         * @param y the panel's bottom edge, in world units
         * @param width the panel's width, in world units
         * @param height the panel's height, in world units
         * @param rowCount the number of rows to divide the content area into
         */
        public void set(float x, float y, float width, float height, int rowCount) {
            this.x = x;
            this.width = width;
            this.top = y + height - contentTopOffset;
            this.rowHeight = rowHeight(height, rowCount);
        }

        /**
         * Returns the top edge of the
         * given row, per the last {@link #set} call.
         *
         * @param rowIndex the row's index, counting top to bottom from zero
         */
        public float top(int rowIndex) {
            return top - rowIndex * (rowHeight + rowGap);
        }

        /**
         * Draws a left-aligned label at the given
         * row, vertically centered within the row's height.
         *
         * @param batch the batch to draw into
         * @param rowIndex the row's index, counting top to bottom from zero
         * @param label the label to draw
         */
        public void render(SpriteBatch batch, int rowIndex, HudText label) {
            label.render(batch, x + padding, centeredTop(rowIndex, label));
        }

        /**
         * Draws a left-aligned label and a right-aligned value
         * at the given row, vertically centered within the row's height.
         *
         * @param batch the batch to draw into
         * @param rowIndex the row's index, counting top to bottom from zero
         * @param label the label to draw
         * @param value the value to draw
         */
        public void render(SpriteBatch batch, int rowIndex, HudText label, HudText value) {
            float rowTop = centeredTop(rowIndex, label);
            label.render(batch, x + padding, rowTop);
            value.render(batch, x + width - padding, rowTop);
        }

        /**
         * Draws a left-aligned label and a right-aligned color
         * counts group at the given row, vertically centered within the row's height.
         *
         * @param batch the batch to draw into
         * @param rowIndex the row's index, counting top to bottom from zero
         * @param label the label to draw
         * @param counts the color counts to draw
         */
        public void render(SpriteBatch batch, int rowIndex, HudText label, HudPackageColorCounts counts) {
            float rowTop = centeredTop(rowIndex, label);
            label.render(batch, x + padding, rowTop);
            counts.render(batch, x + width - padding, rowTop);
        }

        /**
         * Draws a left-aligned label and a right-aligned package
         * color text at the given row, vertically centered within the row's height.
         *
         * @param batch the batch to draw into
         * @param rowIndex the row's index, counting top to bottom from zero
         * @param label the label to draw
         * @param value the package color text to draw
         */
        public void render(SpriteBatch batch, int rowIndex, HudText label, HudPackageColorText value) {
            float rowTop = centeredTop(rowIndex, label);
            label.render(batch, x + padding, rowTop);
            value.render(batch, x + width - padding, rowTop);
        }

        /**
         * Draws a left-aligned label and right-aligned
         * time text at the given row, vertically
         * centered within the row's height.
         *
         * @param batch the batch to draw into
         * @param rowIndex the row's index, counting top to bottom from zero
         * @param label the label to draw
         * @param value the time text to draw
         */
        public void render(SpriteBatch batch, int rowIndex, HudText label, HudTimeText value) {
            float rowTop = centeredTop(rowIndex, label);
            label.render(batch, x + padding, rowTop);
            value.render(batch, x + width - padding, rowTop);
        }

        /**
         * Returns the y position that vertically centers
         * {@code text} within the given row's height.
         *
         * @param rowIndex the row's index, counting top to bottom from zero
         * @param text the text being centered for its rendered height
         */
        private float centeredTop(int rowIndex, HudText text) {
            return top(rowIndex) - (rowHeight - text.height()) / 2f;
        }
    }
}
