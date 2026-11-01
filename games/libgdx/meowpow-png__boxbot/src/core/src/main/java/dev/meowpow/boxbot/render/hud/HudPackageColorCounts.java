package dev.meowpow.boxbot.render.hud;

import dev.meowpow.boxbot.gdx.HotPath;
import dev.meowpow.boxbot.render.RenderColors;

import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;

/**
 * A right-aligned row of per-color package counts,
 * each shown as a small colored box followed by its count.
 */
@HotPath
public final class HudPackageColorCounts {

    private static final String GAP = "  ";
    private static final float BOX_SIZE_RATIO = 0.55f;

    private final HudPackageColorBox redBox, greenBox, blueBox;
    private final HudText red, green, blue;

    private final float boxSize;

    /**
     * Creates a color counts row drawn with the given font.
     *
     * @param font the font to draw every segment with
     */
    HudPackageColorCounts(BitmapFont font) {
        redBox = new HudPackageColorBox(RenderColors.PACKAGE_RED);
        greenBox = new HudPackageColorBox(RenderColors.PACKAGE_GREEN);
        blueBox = new HudPackageColorBox(RenderColors.PACKAGE_BLUE);

        red = new HudText(font, HudText.Alignment.LEFT, RenderColors.PACKAGE_RED);
        green = new HudText(font, HudText.Alignment.LEFT, RenderColors.PACKAGE_GREEN);
        blue = new HudText(font, HudText.Alignment.LEFT, RenderColors.PACKAGE_BLUE);

        boxSize = font.getLineHeight() * BOX_SIZE_RATIO;
    }

    /**
     * Replaces the count displayed for each color.
     *
     * @param redCount the count of red packages
     * @param greenCount the count of green packages
     * @param blueCount the count of blue packages
     */
    void setCounts(int redCount, int greenCount, int blueCount) {
        setSegment(red, redCount, GAP);
        setSegment(green, greenCount, GAP);
        setSegment(blue, blueCount, "");
    }

    /**
     * Draws every segment's box.
     *
     * @param renderer the shape renderer to draw into
     * @param rightX the group's right edge, in world units
     * @param centerY the group's vertical center, in world units
     */
    void renderSwatches(ShapeRenderer renderer, float rightX, float centerY) {
        float x = rightX - totalWidth();
        float boxY = centerY - boxSize / 2f;

        redBox.render(renderer, x, boxY, boxSize);
        x += boxSize + red.width();

        greenBox.render(renderer, x, boxY, boxSize);
        x += boxSize + green.width();

        blueBox.render(renderer, x, boxY, boxSize);
    }

    /**
     * Draws every segment's count text.
     *
     * @param batch the batch to draw into
     * @param rightX the group's right edge, in world units
     * @param y the top draw position, in world units
     */
    void render(SpriteBatch batch, float rightX, float y) {
        float x = rightX - totalWidth();

        x += boxSize;
        red.render(batch, x, y);
        x += red.width();

        x += boxSize;
        green.render(batch, x, y);
        x += green.width();

        x += boxSize;
        blue.render(batch, x, y);
    }

    private float totalWidth() {
        return 3f * boxSize + red.width() + green.width() + blue.width();
    }

    private static void setSegment(HudText text, int count, String suffix) {
        var content = text.content();
        content.setLength(0);
        content.append(" x").append(count).append(suffix);
    }
}
