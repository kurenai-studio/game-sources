package com.jgarivera.blitzbit.input.actions;

import com.badlogic.ashley.core.Entity;
import com.jgarivera.blitzbit.input.action.Action;
import com.jgarivera.blitzbit.world.World;
import com.jgarivera.blitzbit.world.physics.components.PhysicsComponentMapper;
import com.jgarivera.blitzbit.world.physics.components.SpeedComponent;
import com.jgarivera.blitzbit.world.physics.components.VelocityComponent;

public class MoveDown implements Action {

    public boolean enter(World world) {
        Entity player = world.getPlayer();
        VelocityComponent velocity = PhysicsComponentMapper.VELOCITY.get(player);
        SpeedComponent speed = PhysicsComponentMapper.SPEED.get(player);

        velocity.y = -speed.speed;

        return true;
    }

    public boolean exit(World world) {
        Entity player = world.getPlayer();
        VelocityComponent velocity = PhysicsComponentMapper.VELOCITY.get(player);

        velocity.y = 0;

        return true;
    }
}
