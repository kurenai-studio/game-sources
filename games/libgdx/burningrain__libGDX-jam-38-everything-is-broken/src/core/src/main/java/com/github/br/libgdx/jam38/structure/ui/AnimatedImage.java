package com.github.br.libgdx.jam38.structure.ui;

import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.ui.Image;

public class AnimatedImage extends Image {

    private final AnimatedDrawable animatedDrawable;

    public AnimatedImage(Animation<TextureRegion> animation) {
        super(new AnimatedDrawable(animation));
        this.setSize(this.getWidth(), this.getHeight());
        this.setOrigin(this.getWidth() / 2f, this.getHeight() / 2f);

        this.animatedDrawable = (AnimatedDrawable) getDrawable();

        pause();
    }

    public void play() {
        animatedDrawable.play();
    }

    public void pause() {
        animatedDrawable.pause();
    }

    public void resetAndPause() {
        animatedDrawable.resetAndPause();
    }

    public void setFrameAndPause(int frame) {
        animatedDrawable.setFrameAndPause(frame);
    }

    public boolean isAnimationEnd() {
        return animatedDrawable.isAnimationEnd();
    }

    public boolean isPaused() {
        return animatedDrawable.isPaused();
    }

    public void setPlayMode(Animation.PlayMode playMode) {
        animatedDrawable.setPlayMode(playMode);
    }

    public void setFrameDuration(float frameDuration) {
        animatedDrawable.setFrameDuration(frameDuration);
    }

    public Animation.PlayMode getPlayMode() {
        return animatedDrawable.getPlayMode();
    }

    public float getFrameDuration() {
        return animatedDrawable.getFrameDuration();
    }

    public float getAnimationDuration() {
        return animatedDrawable.getAnimationDuration();
    }

    public boolean isLooping() {
        return animatedDrawable.isLooping();
    }

    public void setLooping(boolean isLooping) {
        animatedDrawable.setLooping(isLooping);
    }

    public void setStateTime(float stateTime) {
        animatedDrawable.setStateTime(stateTime);
    }

    public float getStateTime() {
        return animatedDrawable.getStateTime();
    }

}
