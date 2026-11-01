package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.scenes.scene2d.utils.ScissorStack;
import com.badlogic.gdx.utils.viewport.Viewport;

import java.util.Objects;

/**
 * A vertically scrollable,
 * clipped list of fixed-height rows.
 */
@HotPath
public final class HudScrollList {

    private final float rowGap;
    private final Rectangle clipBounds = new Rectangle();
    private final Rectangle scissors = new Rectangle();

    private int rowCount;
    private float rowHeight;
    private float scrollOffset;

    /**
     * Creates a scroll list of rows
     * with the given fixed height and gap.
     *
     * @param rowHeight the height of every row, in world units
     * @param rowGap the vertical gap between adjacent rows, in world units
     *
     * @throws IllegalArgumentException if {@code rowHeight} is not
     * positive, or {@code rowGap} is negative
     */
    public HudScrollList(float rowHeight, float rowGap) {
        if (rowHeight <= 0f) {
            var message = "rowHeight must be positive: " + rowHeight;
            throw new IllegalArgumentException(message);
        }
        if (rowGap < 0f) {
            var message = "rowGap must not be negative: " + rowGap;
            throw new IllegalArgumentException(message);
        }
        this.rowHeight = rowHeight;
        this.rowGap = rowGap;
    }

    /**
     * Replaces the fixed height every row is drawn at.
     *
     * @param rowHeight the new row height, in world units
     *
     * @throws IllegalArgumentException if {@code rowHeight} is not positive
     */
    void setRowHeight(float rowHeight) {
        if (rowHeight <= 0f) {
            var message = "rowHeight must be positive: " + rowHeight;
            throw new IllegalArgumentException(message);
        }
        this.rowHeight = rowHeight;
    }

    /**
     * Sets the number of rows backing this list.
     * <p>
     * The current scroll offset will be clamped if it no longer fits.
     *
     * @param rowCount the backing row count
     *
     * @throws IllegalArgumentException if {@code rowCount} is negative
     */
    public void setRowCount(int rowCount) {
        if (rowCount < 0) {
            var message = "rowCount must not be negative: " + rowCount;
            throw new IllegalArgumentException(message);
        }
        this.rowCount = rowCount;
        scrollOffset = Math.clamp(scrollOffset, 0f, maxScroll());
    }

    /**
     * Scrolls by the given amount,
     * clamped to the list's scroll range.
     *
     * @param delta the amount to scroll by, in world units
     */
    public void scrollBy(float delta) {
        scrollOffset = Math.clamp(scrollOffset + delta, 0f, maxScroll());
    }

    /**
     * Draws every row currently visible
     * within the given bounds, clipped to those bounds.
     *
     * @param batch the batch to draw into
     * @param viewport the viewport the batch is projected with
     * @param x the list's left edge, in world units
     * @param y the list's bottom edge, in world units
     * @param width the list's width, in world units
     * @param height the list's height, in world units
     * @param rowRenderer draws each visible row
     *
     * @throws NullPointerException if {@code rowRenderer} is null
     */
    public void render(
            SpriteBatch batch,
            Viewport viewport,
            float x,
            float y,
            float width,
            float height,
            HudRowRenderer rowRenderer
    ) {
        Objects.requireNonNull(rowRenderer, "rowRenderer must not be null");

        clipBounds.set(x, y, width, height);
        ScissorStack.calculateScissors(
                viewport.getCamera(),
                viewport.getScreenX(),
                viewport.getScreenY(),
                viewport.getScreenWidth(),
                viewport.getScreenHeight(),
                batch.getTransformMatrix(),
                clipBounds,
                scissors
        );
        batch.flush();
        if (!ScissorStack.pushScissors(scissors)) {
            return;
        }
        try {
            float stride = rowHeight + rowGap;
            int firstVisible = Math.max(0, (int) Math.floor(scrollOffset / stride));
            int visibleRows = (int) Math.ceil(height / stride) + 1;
            int lastVisible = Math.min(rowCount, firstVisible + visibleRows);

            float top = y + height;
            for (int i = firstVisible; i < lastVisible; i++) {
                float rowTop = top - (i * stride - scrollOffset);
                float rowY = rowTop - rowHeight;

                rowRenderer.renderRow(batch, i, x, rowY, width, rowHeight);
            }
            batch.flush();
        }
        finally {
            ScissorStack.popScissors();
        }
    }

    /**
     * Draws a scrollbar thumb to reflect how much content is
     * visible and how far scrolled from the last {@link #render} call.
     * <p>
     * Draws nothing if every row already fits without scrolling.
     *
     * @param renderer the shape renderer to draw into
     * @param color the thumb's color
     * @param trackRight the track's right edge, in world units
     * @param thumbWidth the thumb's width, in world units
     */
    public void renderScrollbar(
            ShapeRenderer renderer,
            Color color,
            float trackRight,
            float thumbWidth
    ) {
        float maxScroll = maxScroll();
        if (maxScroll <= 0f) {
            return;
        }
        float trackHeight = clipBounds.height;
        float contentHeight = totalContentHeight();
        float thumbHeight = trackHeight * (trackHeight / contentHeight);
        float thumbTravel = trackHeight - thumbHeight;
        float scrollFraction = scrollOffset / maxScroll;

        float thumbX = trackRight - thumbWidth;
        float thumbY = clipBounds.y + trackHeight - thumbHeight - scrollFraction * thumbTravel;

        renderer.setColor(color);
        renderer.rect(thumbX, thumbY, thumbWidth, thumbHeight);
    }

    private float maxScroll() {
        return Math.max(0f, totalContentHeight() - clipBounds.height);
    }

    private float totalContentHeight() {
        return rowCount * rowHeight + Math.max(0, rowCount - 1) * rowGap;
    }
}
