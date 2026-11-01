package dev.meowpow.boxbot.render;

import dev.meowpow.boxbot.engine.spatial.grid.TileSize;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.input.selection.SelectionPair;
import dev.meowpow.boxbot.input.selection.SelectionTarget;
import dev.meowpow.boxbot.render.assets.BakedFont;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Disposable;

import java.util.Objects;

/**
 * Draws a corner-bracket highlight around the
 * currently selected entity and every queued pair.
 */
@HotPath
public final class SelectionRenderer implements Disposable {

    private static final float CORNER_LENGTH_FRACTION = 0.2f;
    private static final float LINE_THICKNESS = 1.5f;

    /**
     * Inset of the queue-order number from
     * the selection box's top-right corner.
     */
    private static final float QUEUE_NUMBER_INSET = 4f;

    private final BakedFont queueNumberFont;

    private final ShapeRenderer shapeRenderer = new ShapeRenderer();
    private final SpriteBatch batch = new SpriteBatch();
    private final GlyphLayout layout = new GlyphLayout();
    private final Rectangle bounds = new Rectangle();

    /**
     * Cache of "1", "2", ... labels, grown
     * on demand instead of formatted every frame.
     */
    private String[] queueNumbers = new String[0];

    /**
     * Creates a renderer that labels queued
     * pairs' order using {@code queueNumberFont}.
     *
     * @throws NullPointerException if {@code queueNumberFont} is null
     */
    public SelectionRenderer(BakedFont queueNumberFont) {
        Objects.requireNonNull(queueNumberFont, "queueNumberFont must not be null");
        this.queueNumberFont = queueNumberFont;
    }

    /**
     * Draws corner brackets around the primary, secondary,
     * staging, and queued selections, whichever are non-null.
     * <p>
     * Queued pairs are also numbered with their FIFO dispatch order.
     *
     * @param camera the camera whose view the brackets render into
     * @param tileSize the map's tile size, in pixels
     * @param primary the current primary selection, or null if nothing is selected
     * @param secondary the current secondary selection, or null if nothing is selected
     * @param stagingPrimary the primary of the pair being staged for the queue, or null
     * @param stagingSecondary the secondary of the pair being staged for the queue, or null
     * @param queuedPairs pairs queued to run once the current selection is done
     *
     * @throws NullPointerException if {@code queuedPairs} is null
     */
    public void render(
            Camera camera,
            TileSize tileSize,
            @Nullable SelectionTarget primary,
            @Nullable SelectionTarget secondary,
            @Nullable SelectionTarget stagingPrimary,
            @Nullable SelectionTarget stagingSecondary,
            ArrayView<SelectionPair> queuedPairs
    ) {
        Objects.requireNonNull(queuedPairs, "queuedPairs must not be null");

        boolean noSelection = primary == null && secondary == null;
        boolean noStagingSelection = stagingPrimary == null && stagingSecondary == null;

        if (noSelection && noStagingSelection && queuedPairs.isEmpty()) {
            return;
        }
        shapeRenderer.setProjectionMatrix(camera.combined);
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);

        if (primary != null) {
            shapeRenderer.setColor(RenderColors.SELECTION_PRIMARY);
            renderTarget(primary, tileSize);
        }
        if (secondary != null) {
            shapeRenderer.setColor(RenderColors.SELECTION_SECONDARY);
            renderTarget(secondary, tileSize);
        }
        if (stagingPrimary != null) {
            shapeRenderer.setColor(RenderColors.SELECTION_QUEUED_PRIMARY);
            renderTarget(stagingPrimary, tileSize);
        }
        if (stagingSecondary != null) {
            shapeRenderer.setColor(RenderColors.SELECTION_QUEUED_SECONDARY);
            renderTarget(stagingSecondary, tileSize);
        }
        if (!queuedPairs.isEmpty()) {
            for (int i = 0; i < queuedPairs.size(); i++) {
                var pair = queuedPairs.get(i);

                shapeRenderer.setColor(RenderColors.SELECTION_QUEUED_PRIMARY);
                renderTarget(pair.primary(), tileSize);

                shapeRenderer.setColor(RenderColors.SELECTION_QUEUED_SECONDARY);
                renderTarget(pair.secondary(), tileSize);
            }
        }
        shapeRenderer.end();

        if (!queuedPairs.isEmpty()) {
            renderQueueNumbers(camera, tileSize, queuedPairs);
        }
    }

    private void renderQueueNumbers(
            Camera camera,
            TileSize tileSize,
            ArrayView<SelectionPair> queuedPairs
    ) {
        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        for (int i = 0; i < queuedPairs.size(); i++) {
            var pair = queuedPairs.get(i);
            var number = queueNumber(i);

            drawQueueNumber(number, pair.primary(), tileSize);
            drawQueueNumber(number, pair.secondary(), tileSize);
        }
        batch.end();
    }

    private String queueNumber(int index) {
        if (index >= queueNumbers.length) {
            var grown = new String[index + 1];
            System.arraycopy(queueNumbers, 0, grown, 0, queueNumbers.length);
            for (int i = queueNumbers.length; i < grown.length; i++) {
                grown[i] = Integer.toString(i + 1);
            }
            queueNumbers = grown;
        }
        return queueNumbers[index];
    }

    private void drawQueueNumber(
            String number,
            SelectionTarget target,
            TileSize tileSize
    ) {
        var font = queueNumberFont.font();
        target.bounds(bounds, tileSize);
        layout.setText(font, number);

        float x = bounds.x + bounds.width - layout.width - QUEUE_NUMBER_INSET;
        float y = bounds.y + bounds.height - QUEUE_NUMBER_INSET;

        font.draw(batch, layout, x, y);
    }

    private void renderTarget(SelectionTarget target, TileSize tileSize) {
        switch (target) {
            case SelectionTarget.ShelfPackage t -> renderStandard(t, tileSize);
            case SelectionTarget.BayPackage t -> renderStandard(t, tileSize);
            case SelectionTarget.Station t -> renderStation(t, tileSize);
            case SelectionTarget.EmptyShelf t -> renderStandard(t, tileSize);
            case SelectionTarget.BayDestination t -> renderBayDestination(t, tileSize);
        }
    }

    private void renderStandard(SelectionTarget target, TileSize tileSize) {
        float padding = -3f;
        float offsetX = -0.5f;
        float offsetY = -0.5f;

        target.bounds(bounds, tileSize);
        drawBrackets(bounds, padding, offsetX, offsetY);
    }

    private void renderBayDestination(
            SelectionTarget.BayDestination target,
            TileSize tileSize
    ) {
        float padding = -5f;
        float offsetX = 0f;
        float offsetY = 1.5f;

        target.bounds(bounds, tileSize);
        drawBrackets(bounds, padding, offsetX, offsetY);
    }

    private void renderStation(SelectionTarget.Station target, TileSize tileSize) {
        float padding = -10f;

        target.bounds(bounds, tileSize);
        drawBrackets(bounds, padding, 0f, 0f);
    }

    /**
     * Draws corner brackets around the given box.
     *
     * @param box the entity's raw pixel bounds
     * @param padding the amount to grow {@code box} outward on every side
     * @param offsetX the amount to shift the drawn box on the x-axis
     * @param offsetY the amount to shift the drawn box on the y-axis
     */
    private void drawBrackets(Rectangle box, float padding, float offsetX, float offsetY) {
        float x = box.x - padding + offsetX;
        float y = box.y - padding + offsetY;

        float width = box.width + padding * 2f;
        float height = box.height + padding * 2f;

        float cornerLength = Math.min(width, height) * CORNER_LENGTH_FRACTION;
        float right = x + width;
        float top = y + height;

        drawCorner(x, y, cornerLength, cornerLength);
        drawCorner(right, y, -cornerLength, cornerLength);
        drawCorner(x, top, cornerLength, -cornerLength);
        drawCorner(right, top, -cornerLength, -cornerLength);
    }

    private void drawCorner(float x, float y, float dx, float dy) {
        float half = LINE_THICKNESS / 2f;

        float hx = Math.min(x, x + dx) - half;
        float hw = Math.abs(dx) + LINE_THICKNESS;

        shapeRenderer.rect(hx, y - half, hw, LINE_THICKNESS);

        float vy = Math.min(y, y + dy) - half;
        float vh = Math.abs(dy) + LINE_THICKNESS;

        shapeRenderer.rect(x - half, vy, LINE_THICKNESS, vh);
    }

    @Override
    public void dispose() {
        shapeRenderer.dispose();
        batch.dispose();
    }
}
