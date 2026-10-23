package com.jgarivera.blitzbit.world.view.systems;

import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.SortedIteratingSystem;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.jgarivera.blitzbit.input.ToggleManager;
import com.jgarivera.blitzbit.world.World;
import com.jgarivera.blitzbit.world.physics.components.PhysicsComponentMapper;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.view.RenderOrderComparator;
import com.jgarivera.blitzbit.world.view.components.AnimatedSpriteComponent;
import com.jgarivera.blitzbit.world.view.components.RenderOrderComponent;
import com.jgarivera.blitzbit.world.view.components.SizeComponent;
import com.jgarivera.blitzbit.world.view.components.SpriteComponent;
import com.jgarivera.blitzbit.world.view.components.ViewComponentMapper;

public class SpriteOverlaySystem extends SortedIteratingSystem {

    private final World world;
    private final SpriteBatch batch;
    private final BitmapFont font;

    public SpriteOverlaySystem(World world, SpriteBatch batch) {
        super(Family.all(PositionComponent.class, RenderOrderComponent.class)
                .one(SpriteComponent.class, AnimatedSpriteComponent.class).get(), new RenderOrderComparator());
        this.world = world;
        this.batch = batch;

        font = new BitmapFont();
        font.setUseIntegerPositions(false);
        font.getData().setScale(0.01f);
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        if (!isDebugMode()) {
            return;
        }

        PositionComponent position = PhysicsComponentMapper.POSITION.get(entity);
        SizeComponent size = ViewComponentMapper.getSizeComponentOrDefault(entity);

        float x = position.x;
        float y = position.y;
        float width = size.width;
        float height = size.height;
        float originX = width / 2.0f;
        float originY = height / 2.0f;
        String overlay = String.format("x=%.2fm,y=%.2fm\nw=%.2fm, h=%.2fm", x, y, width, height);

        font.draw(batch, overlay, x - originX, y - originY);
    }

    private boolean isDebugMode() {
        return world.getToggleManager().getToggle(ToggleManager.DEBUG_MODE);
    }
}
