package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.physics.box2d.World;
import com.ychstudio.builders.ActorBuilder;
import com.ychstudio.ecs.components.TentComponent;

public class TentSystem extends IteratingSystem {

    protected ComponentMapper<TentComponent> tentM = ComponentMapper.getFor(TentComponent.class);

    private World world;

    public TentSystem(World world) {
        super(Family.all(TentComponent.class).get());
        this.world = world;
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        TentComponent tent = tentM.get(entity);

        tent.countDown -= deltaTime;

        if (tent.isTimeUp()) {
            if (!tent.isFull()) {
                tent.currentVillagers++;
                ActorBuilder actorBuilder = ActorBuilder.getInstance(world, getEngine());
                actorBuilder.createVillager(tent);
            }
            tent.resetCountDown();
        }
    }

}
