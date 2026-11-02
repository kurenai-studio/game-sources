package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.ychstudio.ecs.components.AnimationComponent;
import com.ychstudio.ecs.components.RendererComponent;

public class AnimationSystem extends IteratingSystem {

    protected ComponentMapper<AnimationComponent> animationM = ComponentMapper.getFor(AnimationComponent.class);
    protected ComponentMapper<RendererComponent> rendererM = ComponentMapper.getFor(RendererComponent.class);

    public AnimationSystem() {
        super(Family.all(AnimationComponent.class, RendererComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        AnimationComponent animation = animationM.get(entity);
        RendererComponent renderer = rendererM.get(entity);
        
        animation.update(deltaTime);

        Animation anim = animation.getAnimation();
        renderer.sprite.setRegion(anim.getKeyFrame(animation.getAnimTime()));
    }

}
