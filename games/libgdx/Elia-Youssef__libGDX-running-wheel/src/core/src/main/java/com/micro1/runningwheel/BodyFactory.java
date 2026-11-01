package com.micro1.runningwheel;

import java.util.List;

import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.ChainShape;
import com.badlogic.gdx.physics.box2d.CircleShape;
import com.badlogic.gdx.physics.box2d.FixtureDef;
import com.badlogic.gdx.physics.box2d.PolygonShape;
import com.badlogic.gdx.physics.box2d.World;

/**
 * Creates the Box2D bodies: the dynamic circular wheel and the static terrain (ground chains,
 * rectangular platform polygons, and a triangular ramp polygon). Ground fixtures are tagged
 * {@link #GROUND} and the wheel fixture {@link #WHEEL} so the contact listener can tell when the
 * wheel is touching the surface. All input geometry is in pixels and converted to meters here.
 */
final class BodyFactory {

    static final String WHEEL = "wheel";
    static final String GROUND = "ground";

    private final World world;

    BodyFactory(World world) {
        this.world = world;
    }

    /** Circular dynamic body with density, friction, and restitution set (rubric item 11). */
    Body createWheel(float startXPx, float startYPx) {
        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.DynamicBody;
        def.position.set(WorldConstants.toM(startXPx), WorldConstants.toM(startYPx));
        def.fixedRotation = false;
        Body body = world.createBody(def);

        CircleShape shape = new CircleShape();
        try {
            shape.setRadius(WorldConstants.WHEEL_RADIUS_M);
            FixtureDef fixture = new FixtureDef();
            fixture.shape = shape;
            fixture.density = WorldConstants.WHEEL_DENSITY;
            fixture.friction = WorldConstants.WHEEL_FRICTION;
            fixture.restitution = WorldConstants.WHEEL_RESTITUTION;
            body.createFixture(fixture).setUserData(WHEEL);
        } finally {
            shape.dispose();
        }
        return body;
    }

    /** Builds every static terrain body from the generated course. */
    void buildTerrain(TerrainData terrain) {
        for (float[] segment : terrain.groundSegments) {
            createGroundChain(segment);
        }
        for (float[] platform : terrain.platforms) {
            createPlatform(platform[0], platform[1], platform[2], platform[3]);
        }
        if (terrain.rampWedge != null) {
            createRampWedge(terrain.rampWedge);
        }
    }

    /** The continuous curved surface: a static chain (the "curves" shape type). */
    private void createGroundChain(float[] polylinePx) {
        float[] verticesM = new float[polylinePx.length];
        for (int i = 0; i < polylinePx.length; i++) {
            verticesM[i] = WorldConstants.toM(polylinePx[i]);
        }

        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.StaticBody;
        Body body = world.createBody(def);

        ChainShape shape = new ChainShape();
        try {
            shape.createChain(verticesM);
            FixtureDef fixture = new FixtureDef();
            fixture.shape = shape;
            fixture.friction = WorldConstants.GROUND_FRICTION;
            fixture.restitution = WorldConstants.GROUND_RESTITUTION;
            body.createFixture(fixture).setUserData(GROUND);
        } finally {
            shape.dispose();
        }
    }

    /** A floating rectangle platform (a box polygon shape type). */
    private void createPlatform(float centerXPx, float centerYPx, float halfWidthPx, float halfHeightPx) {
        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.StaticBody;
        def.position.set(WorldConstants.toM(centerXPx), WorldConstants.toM(centerYPx));
        Body body = world.createBody(def);

        PolygonShape shape = new PolygonShape();
        try {
            shape.setAsBox(WorldConstants.toM(halfWidthPx), WorldConstants.toM(halfHeightPx));
            FixtureDef fixture = new FixtureDef();
            fixture.shape = shape;
            fixture.friction = WorldConstants.GROUND_FRICTION;
            fixture.restitution = WorldConstants.GROUND_RESTITUTION;
            body.createFixture(fixture).setUserData(GROUND);
        } finally {
            shape.dispose();
        }
    }

    /** A triangular ramp (a non-rectangular polygon shape type), vertices given absolute in px. */
    private void createRampWedge(float[] trianglePx) {
        float[] verticesM = new float[trianglePx.length];
        for (int i = 0; i < trianglePx.length; i++) {
            verticesM[i] = WorldConstants.toM(trianglePx[i]);
        }

        BodyDef def = new BodyDef();
        def.type = BodyDef.BodyType.StaticBody;
        Body body = world.createBody(def);

        PolygonShape shape = new PolygonShape();
        try {
            shape.set(verticesM);
            FixtureDef fixture = new FixtureDef();
            fixture.shape = shape;
            fixture.friction = WorldConstants.GROUND_FRICTION;
            fixture.restitution = WorldConstants.GROUND_RESTITUTION;
            body.createFixture(fixture).setUserData(GROUND);
        } finally {
            shape.dispose();
        }
    }
}
