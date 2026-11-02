package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.ychstudio.ecs.components.LifeComponent;

public class LifeSystem extends IteratingSystem {

    protected ComponentMapper<LifeComponent> lifeM = ComponentMapper.getFor(LifeComponent.class);

    public LifeSystem() {
        super(Family.all(LifeComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        LifeComponent life = lifeM.get(entity);

        if (!life.isDead()) {
            life.update(deltaTime);

            if (life.canStartRecover()) {
                if (life.canDoRecovery()) {
                    life.recoverHp(1);
                }
            }
        }
    }

}
