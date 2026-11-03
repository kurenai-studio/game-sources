package io.github.darellanodev.monkeybananarun;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

public class AnimationHelper {

    public static Animation<TextureRegion> getAnimation(Texture texture) {

        int FRAME_COLS = 6;
        int FRAME_ROWS = 1;
        int FRAME_WIDTH = 128;
        int FRAME_HEIGHT = 128;
        TextureRegion[][] tmp = TextureRegion.split(texture, FRAME_WIDTH, FRAME_HEIGHT);
        TextureRegion[] frames = new TextureRegion[FRAME_COLS * FRAME_ROWS];

        int index = 0;
        for (int i = 0; i < FRAME_ROWS; i++) {
            for (int j = 0; j < FRAME_COLS; j++) {
                frames[index++] = tmp[i][j];
            }
        }

        return new Animation<>(0.1f, frames);
    }

}
