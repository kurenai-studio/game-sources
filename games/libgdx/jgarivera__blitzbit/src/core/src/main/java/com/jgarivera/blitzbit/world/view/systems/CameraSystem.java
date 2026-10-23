package com.jgarivera.blitzbit.world.view.systems;

import com.badlogic.ashley.core.Entity;
import com.badlogic.ashley.core.Family;
import com.badlogic.ashley.systems.IteratingSystem;
import com.jgarivera.blitzbit.graphics.Camera;
import com.jgarivera.blitzbit.world.World;
import com.jgarivera.blitzbit.world.physics.components.PhysicsComponentMapper;
import com.jgarivera.blitzbit.world.physics.components.PositionComponent;
import com.jgarivera.blitzbit.world.view.components.CameraFollowComponent;
import com.jgarivera.blitzbit.world.view.components.SizeComponent;
import com.jgarivera.blitzbit.world.view.components.ViewComponentMapper;

public class CameraSystem extends IteratingSystem {

    private final Camera camera;

    public CameraSystem(World world) {
        super(Family.all(CameraFollowComponent.class, PositionComponent.class, SizeComponent.class).get());
        camera = world.getCamera();
    }

    @Override
    protected void processEntity(Entity entity, float deltaTime) {
        CameraFollowComponent cameraFollow = ViewComponentMapper.CAMERA_FOLLOW.get(entity);

        if (!cameraFollow.shouldFollow) {
            return;
        }

        PositionComponent position = PhysicsComponentMapper.POSITION.get(entity);
        SizeComponent size = ViewComponentMapper.SIZE.get(entity);

        float followX = position.x;
        float followY = position.y;
        float interpolation = 0.2f * camera.zoom;

        camera.followLerp(followX, followY, interpolation);
    }
}
