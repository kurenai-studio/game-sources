package com.ychstudio.ecs.systems;

import com.badlogic.ashley.core.ComponentMapper;
import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.badlogic.gdx.physics.box2d.Body;
import com.ychstudio.ecs.components.AnimationComponent;
import com.ychstudio.ecs.components.HunterComponent;
import com.ychstudio.ecs.components.RigidBodyComponent;
import com.ychstudio.ecs.components.StateComponent;

public class HunterSystem extends IteratingSystem {

    protected ComponentMapper<HunterComponent> hunterM = ComponentMapper.getFor(HunterComponent.class);
    protected ComponentMapper<RigidBodyComponent> rigidBodyM = ComponentMapper.getFor(RigidBodyComponent.class);
    protected ComponentMapper<AnimationComponent> animationM = ComponentMapper.getFor(AnimationComponent.class);
    protected ComponentMapper<StateComponent> stateM = ComponentMapper.getFor(StateComponent.class);
    
    public HunterSystem() {
        super(Family.all(HunterComponent.class, RigidBodyComponent.class, AnimationComponent.class, StateComponent.class).get());
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        HunterComponent hunter = hunterM.get(entity);
        RigidBodyComponent rigidBody = rigidBodyM.get(entity);
        AnimationComponent animation = animationM.get(entity);
        StateComponent state = stateM.get(entity);
        
        Body body = rigidBody.body;
        
        
        switch(state.getState()) {
            case HunterComponent.STATE_ATTACK:
                break;
            case HunterComponent.STATE_WALK:
                break;
            case HunterComponent.STATE_DIE:
                break;
            case HunterComponent.STATE_IDLE:
            default:
                break;
        }
    }

}
