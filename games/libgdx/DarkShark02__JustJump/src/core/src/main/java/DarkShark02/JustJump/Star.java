package DarkShark02.JustJump;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;

public class Star {
    private final Rectangle rect;
    private final Texture texture;
    private boolean collected = false;

    public Star(float x, float y, float width, float height, Texture texture) {
        this.rect = new Rectangle(x, y, width, height);
        this.texture = texture;
    }

    public void draw(SpriteBatch batch) {
        if (!collected) {
            batch.draw(texture, rect.x, rect.y, rect.width, rect.height);
        }
    }

    public Rectangle getRect() {
        return rect;
    }

    public boolean isCollected() {
        return collected;
    }

    public void setCollected(boolean collected) {
        this.collected = collected;
    }

    public Texture getTexture() {
        return texture;
    }

    public void dispose() {
        texture.dispose();
    }
}