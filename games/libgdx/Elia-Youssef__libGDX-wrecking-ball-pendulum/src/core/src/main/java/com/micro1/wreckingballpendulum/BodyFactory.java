package com.micro1.wreckingballpendulum;

import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.CircleShape;
import com.badlogic.gdx.physics.box2d.FixtureDef;
import com.badlogic.gdx.physics.box2d.PolygonShape;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.physics.box2d.joints.DistanceJoint;
import com.badlogic.gdx.physics.box2d.joints.DistanceJointDef;

final class BodyFactory {

    private final World world;

    BodyFactory(World world) {
        this.world = world;
    }

    Body createFloor() {
        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.StaticBody;
        def.position.set(WorldConstants.FLOOR_HALF_WIDTH_M, WorldConstants.FLOOR_HALF_HEIGHT_M);
        Body body = world.createBody(def);

        PolygonShape shape = new PolygonShape();
        try {
            shape.setAsBox(WorldConstants.FLOOR_HALF_WIDTH_M, WorldConstants.FLOOR_HALF_HEIGHT_M);
            FixtureDef fixtureDef = new FixtureDef();
            fixtureDef.shape = shape;
            fixtureDef.friction = WorldConstants.FLOOR_FRICTION;
            fixtureDef.restitution = WorldConstants.FLOOR_RESTITUTION;
            body.createFixture(fixtureDef);
        } finally {
            shape.dispose();
        }
        return body;
    }

    Body createBoom() {
        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.KinematicBody;
        def.position.set(WorldConstants.BOOM_HOME_X_M, WorldConstants.BOOM_Y_M);
        return world.createBody(def);
    }

    Body createBlock() {
        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.DynamicBody;
        def.position.set(WorldConstants.BLOCK_HOME_X_M, WorldConstants.BLOCK_HOME_Y_M);
        Body body = world.createBody(def);

        PolygonShape shape = new PolygonShape();
        try {
            shape.setAsBox(WorldConstants.BLOCK_HALF_SIZE_M, WorldConstants.BLOCK_HALF_SIZE_M);
            FixtureDef fixtureDef = new FixtureDef();
            fixtureDef.shape = shape;
            fixtureDef.density = WorldConstants.BLOCK_DENSITY;
            fixtureDef.friction = WorldConstants.BLOCK_FRICTION;
            fixtureDef.restitution = WorldConstants.BLOCK_RESTITUTION;
            body.createFixture(fixtureDef);
        } finally {
            shape.dispose();
        }
        return body;
    }

    Body createBall() {
        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.DynamicBody;
        def.position.set(WorldConstants.BOOM_HOME_X_M, WorldConstants.BALL_HOME_Y_M);
        Body body = world.createBody(def);

        CircleShape shape = new CircleShape();
        try {
            shape.setRadius(WorldConstants.BALL_RADIUS_M);
            FixtureDef fixtureDef = new FixtureDef();
            fixtureDef.shape = shape;
            fixtureDef.density = WorldConstants.BALL_DENSITY;
            fixtureDef.friction = WorldConstants.BALL_FRICTION;
            fixtureDef.restitution = WorldConstants.BALL_RESTITUTION;
            body.createFixture(fixtureDef);
        } finally {
            shape.dispose();
        }
        return body;
    }

    DistanceJoint attachRope(Body boom, Body ball) {
        DistanceJointDef def = new DistanceJointDef();
        def.bodyA = boom;
        def.bodyB = ball;
        def.localAnchorA.set(0f, 0f);
        def.localAnchorB.set(0f, WorldConstants.BALL_RADIUS_M);
        def.length = WorldConstants.ROPE_LENGTH_M;
        def.collideConnected = false;
        return (DistanceJoint) world.createJoint(def);
    }
}
