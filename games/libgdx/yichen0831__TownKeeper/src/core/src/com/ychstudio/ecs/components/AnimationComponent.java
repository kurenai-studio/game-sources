package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.utils.IntMap;

public class AnimationComponent implements Component {

    private IntMap<Animation> animations;
    
    private int currentAnimation;
    private float animTime;

    public AnimationComponent() {
        this(0);
    }
    
    public AnimationComponent(int currentAnimation) {
        animations = new IntMap<>();
        this.currentAnimation = currentAnimation;
        animTime = 0;
    }

    public void putAnimation(int key, Animation animation) {
        animations.put(key, animation);
    }
    
    public void setCurrentAnimation(int currentAnimation) {
        if (this.currentAnimation != currentAnimation) {
            this.currentAnimation = currentAnimation;
            animTime = 0;
        }
    }
    
    public int getCurrentAnimation() {
        return currentAnimation;
    }
    
    public Animation getAnimation() {
        return animations.get(currentAnimation);
    }

    public Animation getAnimation(int key) {
        return animations.get(key);
    }
    
    public float getAnimTime() {
        return animTime;
    }
    
    public void update(float deltaTime) {
        animTime += deltaTime;
    }
}
