package net.zachwalker.eggsort.util;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.TimeUtils;

public final class DrawingHelpers {

    private DrawingHelpers() {
        //private constructor - only static methods on this class
    }

    public static void drawSprite(SpriteBatch batch, TextureRegion textureRegion, Vector2 position) {
        drawSprite(batch, textureRegion, position.x, position.y);
    }

    public static void drawSprite(SpriteBatch batch, TextureRegion textureRegion, float x, float y) {
        batch.draw(
                textureRegion.getTexture(),
                x,
                y,
                0.0f,
                0.0f,
                textureRegion.getRegionWidth(),
                textureRegion.getRegionHeight(),
                1.0f,
                1.0f,
                0.0f,
                textureRegion.getRegionX(),
                textureRegion.getRegionY(),
                textureRegion.getRegionWidth(),
                textureRegion.getRegionHeight(),
                false,
                false
        );
    }

    public static void drawSpriteRotated(SpriteBatch batch, TextureRegion textureRegion, Vector2 position) {
        batch.draw(
                textureRegion.getTexture(),
                position.x,
                position.y,
                0.0f,
                0.0f,
                textureRegion.getRegionWidth(),
                textureRegion.getRegionHeight(),
                1.0f,
                1.0f,
                90.0f,
                textureRegion.getRegionX(),
                textureRegion.getRegionY(),
                textureRegion.getRegionWidth(),
                textureRegion.getRegionHeight(),
                false,
                false
        );
    }

    public static float secondsSince(long nanoTimeStamp) {
        return MathUtils.nanoToSec * (TimeUtils.nanoTime() - nanoTimeStamp);
    }

}
