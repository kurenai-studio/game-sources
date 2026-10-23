package com.jgarivera.blitzbit.world.view.components;

import com.badlogic.ashley.core.Component;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

public class AnimatedSpriteComponent implements Component {

    public String regionName;
    public float frameDuration;
    public Animation.PlayMode playMode = Animation.PlayMode.NORMAL;

    public Animation<TextureRegion> animation;
    public float stateTime = 0;

    public AnimatedSpriteComponent(String regionName, float frameDuration) {
        this.regionName = regionName;
        this.frameDuration = frameDuration;
    }
}
