package io.github.darellanodev.monkeybananarun;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;

public class Fire {
    private final Rectangle bounds;
    private final Animation<TextureRegion> fireAnimation;
    private float stateTime = 0f;
    private float x;
    private float y;
    private final float width = 2f;
    private final float height = 2f;

    public Fire(Texture texture, float initialX, float initialY){
        fireAnimation = AnimationHelper.getAnimation(texture);
        x = initialX;
        y = initialY;
        bounds = createBounds(x, y);
    }

    private Rectangle createBounds(float x, float y) {
        return new Rectangle(x, y, width, height);
    }

    public void update(float deltaTime) {
        stateTime += deltaTime;
        bounds.set(x, y, width, height);
    }

    public TextureRegion getCurrentFrame() {
        return fireAnimation.getKeyFrame(stateTime, true);
    }

    public void draw(SpriteBatch batch){
        batch.draw(getCurrentFrame(), x, y, width, height);
    }

    public Rectangle getBounds() {
        return bounds;
    }

}
