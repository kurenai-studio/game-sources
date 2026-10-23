package DarkShark02.JustJump;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;

public class Heart {
    private final Rectangle rect;
    private final Texture texture;
    private boolean collected = false;

    // Dimensioni visive del cuore
    private final float HEART_VISUAL_WIDTH = 40;
    private final float HEART_VISUAL_HEIGHT = 40;
    
    // Offset per la hitbox del cuore (ricalibrati verticalmente)
    private final float HEART_HITBOX_OFFSET_X = 5;
    private final float HEART_HITBOX_OFFSET_Y = 5;

    public Heart(float x, float y, float width, float height, Texture texture) {
        this.texture = texture;
        this.rect = new Rectangle(x + HEART_HITBOX_OFFSET_X,
                                  y + HEART_HITBOX_OFFSET_Y,
                                  HEART_VISUAL_WIDTH - (HEART_HITBOX_OFFSET_X * 2),
                                  HEART_VISUAL_HEIGHT - (HEART_HITBOX_OFFSET_Y * 2));
    }

    public void draw(SpriteBatch batch) {
        if (!collected) {
            batch.draw(texture, rect.x - HEART_HITBOX_OFFSET_X, rect.y - HEART_HITBOX_OFFSET_Y, HEART_VISUAL_WIDTH, HEART_VISUAL_HEIGHT);
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