package com.jgarivera.blitzbit.world.physics.components;

import com.badlogic.ashley.core.ComponentMapper;

import static com.badlogic.ashley.core.ComponentMapper.getFor;

public class PhysicsComponentMapper {

    public static final ComponentMapper<PositionComponent> POSITION = getFor(PositionComponent.class);
    public static final ComponentMapper<VelocityComponent> VELOCITY = getFor(VelocityComponent.class);
    public static final ComponentMapper<SpeedComponent> SPEED = getFor(SpeedComponent.class);
    public static final ComponentMapper<PhysicsBodyComponent> PHYSICS_BODY = getFor(PhysicsBodyComponent.class);
}
