package DarkShark02.JustJump;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;

public class Spike {
    private final Rectangle rect;
    private final Texture texture;

    // Dimensioni visive delle spine
    private final float SPIKE_VISUAL_WIDTH = 50;
    private final float SPIKE_VISUAL_HEIGHT = 15;

    // Offset per la hitbox delle spine (ricalibrati verticalmente)
    private final float SPIKE_HITBOX_WIDTH_REDUCTION = 10; // Riduci la larghezza
    private final float SPIKE_HITBOX_HEIGHT = 5; // Altezza della hitbox (solo la punta)
    private final float SPIKE_HITBOX_Y_OFFSET = 10; // Sposta la hitbox verso l'alto (sulla punta)

    public Spike(float x, float y, float width, float height, Texture texture) {
        this.texture = texture;
        this.rect = new Rectangle(x + SPIKE_HITBOX_WIDTH_REDUCTION / 2,
                                  y + SPIKE_HITBOX_Y_OFFSET,
                                  SPIKE_VISUAL_WIDTH - SPIKE_HITBOX_WIDTH_REDUCTION,
                                  SPIKE_HITBOX_HEIGHT);
    }

    public void draw(SpriteBatch batch) {
        batch.draw(texture, rect.x - (SPIKE_HITBOX_WIDTH_REDUCTION / 2), rect.y - SPIKE_HITBOX_Y_OFFSET, SPIKE_VISUAL_WIDTH, SPIKE_VISUAL_HEIGHT);
    }

    public Rectangle getRect() {
        return rect;
    }

    public void dispose() {
        texture.dispose();
    }
}