package com.jgarivera.blitzbit.world.view.components;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.gdx.graphics.Color;

import static com.badlogic.ashley.core.ComponentMapper.getFor;

public class ViewComponentMapper {

    public static final ComponentMapper<SizeComponent> SIZE = getFor(SizeComponent.class);
    public static final ComponentMapper<SpriteComponent> SPRITE = getFor(SpriteComponent.class);
    public static final ComponentMapper<AnimatedSpriteComponent> ANIMATED_SPRITE = getFor(AnimatedSpriteComponent.class);
    public static final ComponentMapper<ColorComponent> COLOR = getFor(ColorComponent.class);
    public static final ComponentMapper<CameraFollowComponent> CAMERA_FOLLOW = getFor(CameraFollowComponent.class);
    public static final ComponentMapper<RenderOrderComponent> RENDER_ORDER = getFor(RenderOrderComponent.class);

    public static SizeComponent getSizeComponentOrDefault(Entity entity) {
        SizeComponent size = ViewComponentMapper.SIZE.get(entity);

        if (size != null) {
            return size;
        } else {
            return new SizeComponent(32.0f, 32.0f);
        }
    }

    public static ColorComponent getColorComponentOrDefault(Entity entity) {
        ColorComponent color = ViewComponentMapper.COLOR.get(entity);

        if (color != null) {
            return color;
        } else {
            return new ColorComponent(Color.WHITE);
        }
    }
}
