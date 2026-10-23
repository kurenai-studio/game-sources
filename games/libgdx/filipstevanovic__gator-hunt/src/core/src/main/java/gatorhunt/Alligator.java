package gatorhunt;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/**
 * A single alligator crossing the screen from right to left.
 *
 * Positions (x, y) are in top-left-origin, Y-down screen space, matching
 * touch/mouse input coordinates and the original AWT version. LibGDX's
 * SpriteBatch is Y-up from the bottom-left by default, so draw() flips
 * Y itself rather than relying on a Y-down camera — BitmapFont's own
 * layout math assumes Y-up, so a Y-down camera would render text
 * upside down while leaving sprites looking correct, which is worse to
 * get subtly wrong than converting coordinates explicitly here.
 *
 * width/height are passed in rather than read from the texture here, so
 * this class stays constructible (and testable) without a real Texture.
 */
public class Alligator {

    public int x;
    public int y;
    public final int points;
    public final int width;
    public final int height;
    private final int speed;
    private final Texture image;

    public Alligator(int x, int y, int speed, int points, int width, int height, Texture image) {
        this.x = x;
        this.y = y;
        this.speed = speed;
        this.points = points;
        this.width = width;
        this.height = height;
        this.image = image;
    }

    /** speedMultiplier lets the difficulty ramp speed everyone up together without changing each alligator's base speed. */
    public void updatePosition(float speedMultiplier) {
        x += Math.round(speed * speedMultiplier);
    }

    public boolean hasEscapedOffLeftEdge() {
        return x < -width;
    }

    /** Generous on purpose: a touch is far less precise than a mouse cursor was. */
    public boolean containsPoint(int px, int py) {
        return px >= x && px < x + width && py >= y && py < y + height;
    }

    public void draw(SpriteBatch batch, int screenHeight) {
        batch.draw(image, x, screenHeight - y - height, width, height);
    }
}
