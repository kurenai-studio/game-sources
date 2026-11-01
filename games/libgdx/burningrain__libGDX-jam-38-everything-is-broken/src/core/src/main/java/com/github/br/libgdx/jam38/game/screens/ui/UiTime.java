package com.github.br.libgdx.jam38.game.screens.ui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.GameTime;
import com.github.br.libgdx.jam38.structure.ui.AnimatedImage;

public class UiTime extends Image {

    private final Array<AnimatedImage> timeStones;

    private GameTime gameTime;
    private int secondsInStone = 5;
    private int stoneCount;

    private int prevTime;
    private int prevStoneIndex;

    public UiTime(GameTime gameTime, Array<TextureAtlas.AtlasRegion> atlasRegions) {
        super(atlasRegions.get(0));

        this.gameTime = gameTime;
        this.stoneCount = gameTime.getTimerSec() / secondsInStone;

        Array<AnimatedImage> timeStones = new Array<>(stoneCount);
        for (int i = 0; i < stoneCount; i++) {
            AnimatedImage animatedImage = createAnimatedImage(atlasRegions);
            animatedImage.resetAndPause();
            timeStones.add(animatedImage);
        }
        this.timeStones = timeStones;

        prevTime = gameTime.getTimerSec();
        prevStoneIndex = getCurrentStoneIndex(prevTime);
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        int currentTime = gameTime.getTimerSec();
        if (currentTime == 0) {
            return;
        }

        float deltaTime = Gdx.graphics.getDeltaTime();
        int currentStoneIndex = getCurrentStoneIndex(currentTime);
        if (currentStoneIndex < 0) {
            return;
        }

        AnimatedImage currentStone = timeStones.get(currentStoneIndex);
        currentStone.setStateTime(currentStone.getStateTime() + deltaTime);

        if (currentStoneIndex != prevStoneIndex) {
            // конечно, это бага - привязываться жестко к секунде, но другого выхода не нашел
            if (prevTime - currentTime > GameTime.TIME_STEP) {
                AnimatedImage animatedImage = timeStones.get(prevStoneIndex);
                float prevStateTime = animatedImage.getStateTime();
                currentStone.setStateTime(prevStateTime + deltaTime);
            }

            int i = prevStoneIndex;
            while (i > currentStoneIndex) {
                AnimatedImage prevStone = timeStones.get(i);
                prevStone.setFrameDuration(1 / 20f);
                prevStone.setFrameAndPause(11);
                prevStone.play();
                i--;
            }
        }

        for (int i = 0; i < stoneCount; i++) {
            AnimatedImage animatedImage = timeStones.get(i);
            animatedImage.setPosition(getX() + 0, getY() + 70 * i);
            animatedImage.setScale(getScaleX(), getScaleY());
            animatedImage.draw(batch, parentAlpha);
        }

        prevTime = gameTime.getTimerSec();
        prevStoneIndex = currentStoneIndex;
    }

    private int getCurrentStoneIndex(int currentTime) {
        int currentStoneIndex = (currentTime / secondsInStone) - 1;
        if (currentTime % secondsInStone != 0) {
            currentStoneIndex++; // округление в большую для дробного деления
        }
        return currentStoneIndex;
    }

    private AnimatedImage createAnimatedImage(Array<TextureAtlas.AtlasRegion> regions) {
        AnimatedImage animatedImage = new AnimatedImage(new Animation<>(secondsInStone / 10f, regions));
        animatedImage.setLooping(false);
        animatedImage.setPlayMode(Animation.PlayMode.NORMAL);

        return animatedImage;
    }

}
