package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.physics.box2d.World;
import com.ychstudio.builders.ActorBuilder;
import com.ychstudio.ecs.components.FarmComponent;

public class FarmSystem extends IteratingSystem {

    protected ComponentMapper<FarmComponent> farmM = ComponentMapper.getFor(FarmComponent.class);

    private final World world;

    public FarmSystem(World world) {
        super(Family.all(FarmComponent.class).get());
        this.world = world;
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        FarmComponent farm = farmM.get(entity);

        farm.countDown -= deltaTime;

        if (farm.isTimeUp()) {
            farm.resetCountDown();

            if (!farm.isFull()) {
                farm.currentAnimals++;
                Rectangle rectangle = farm.rectangle;
                float x = MathUtils.random(rectangle.x, rectangle.x + rectangle.width);
                float y = MathUtils.random(rectangle.y, rectangle.y + rectangle.height);

                ActorBuilder actorBuilder = ActorBuilder.getInstance(world, getEngine());
                actorBuilder.createAnimal(x, y, farm);
            }
        }
    }

}
