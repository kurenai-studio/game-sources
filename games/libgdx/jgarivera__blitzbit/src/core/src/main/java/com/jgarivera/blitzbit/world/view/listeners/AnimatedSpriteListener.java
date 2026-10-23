package com.jgarivera.blitzbit.world.view.listeners;

import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.EntityListener;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.utils.Array;
import com.jgarivera.blitzbit.files.AssetManager;
import com.jgarivera.blitzbit.world.view.components.AnimatedSpriteComponent;
import com.jgarivera.blitzbit.world.view.components.ViewComponentMapper;

public class AnimatedSpriteListener implements EntityListener {

    private final TextureAtlas atlas;

    public AnimatedSpriteListener(AssetManager assetManager) {
        atlas = assetManager.get("pack.atlas", TextureAtlas.class);
    }

    @Override
    public void entityAdded(Entity entity) {
        AnimatedSpriteComponent animatedSprite = ViewComponentMapper.ANIMATED_SPRITE.get(entity);

        float frameDuration = animatedSprite.frameDuration;
        String regionName = animatedSprite.regionName;
        Array<TextureAtlas.AtlasRegion> regions = atlas.findRegions(regionName);
        Animation.PlayMode playMode = animatedSprite.playMode;

        animatedSprite.animation = new Animation<>(frameDuration, regions, playMode);

        Gdx.app.debug("AnimatedSpriteListener", String.format("Created animation with region: %s", regionName));
    }

    @Override
    public void entityRemoved(Entity entity) {
    }
}
