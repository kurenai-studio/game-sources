package com.micro1.runningwheel;

import java.util.Random;

import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.Box2D;
import com.badlogic.gdx.physics.box2d.Contact;
import com.badlogic.gdx.physics.box2d.ContactImpulse;
import com.badlogic.gdx.physics.box2d.ContactListener;
import com.badlogic.gdx.physics.box2d.Fixture;
import com.badlogic.gdx.physics.box2d.Manifold;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.GdxNativesLoader;

/**
 * The GL-free Running Wheel simulation: owns the Box2D world (constant downward gravity), the
 * generated terrain, and the wheel. Steps physics on a fixed timestep, drives the wheel by
 * applying opposite torque on Left/Right while it is grounded, tracks elapsed time, and resolves
 * the win (reached the finish) and loss (fell below the lower world boundary) states.
 *
 * Rendering reads it through the getters; it holds no OpenGL resources, so it can be driven
 * directly in a headless test.
 */
public class GameWorld {

    private static final float FIXED_DT = 1f / 60f;
    private static final int MAX_STEPS_PER_FRAME = 5;
    private static final int VELOCITY_ITERATIONS = 8;
    private static final int POSITION_ITERATIONS = 3;

    public enum State {
        PLAYING, WON, LOST
    }

    private final World world;
    private final TerrainData terrain;
    private final Body wheel;

    private State state = State.PLAYING;
    private float elapsedSeconds;
    private float accumulator;
    private int wheelContacts;

    public GameWorld(Random rnd) {
        GdxNativesLoader.load();
        Box2D.init();
        world = new World(new Vector2(0f, WorldConstants.GRAVITY_MPS2), true);
        terrain = TerrainGenerator.generate(rnd);

        BodyFactory factory = new BodyFactory(world);
        factory.buildTerrain(terrain);
        wheel = factory.createWheel(terrain.startXPx, terrain.startYPx);

        world.setContactListener(new GroundContactListener());
    }

    public void update(float delta, boolean leftHeld, boolean rightHeld) {
        if (state != State.PLAYING) {
            return; // round is over: freeze the simulation and the clock
        }
        elapsedSeconds += delta;

        accumulator += delta;
        int steps = 0;
        while (accumulator >= FIXED_DT && steps < MAX_STEPS_PER_FRAME) {
            drive(leftHeld, rightHeld);
            world.step(FIXED_DT, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
            resolveEndState();
            accumulator -= FIXED_DT;
            steps++;
            if (state != State.PLAYING) {
                break;
            }
        }
    }

    /** Applies opposite torque per key, but only while the wheel touches the terrain. */
    private void drive(boolean leftHeld, boolean rightHeld) {
        if (isGrounded()) {
            if (rightHeld && !leftHeld) {
                wheel.applyTorque(-WorldConstants.DRIVE_TORQUE, true); // clockwise -> rolls right
            } else if (leftHeld && !rightHeld) {
                wheel.applyTorque(WorldConstants.DRIVE_TORQUE, true); // counter-clockwise -> rolls left
            }
        }
        float w = wheel.getAngularVelocity();
        if (w > WorldConstants.MAX_ANGULAR_SPEED_RADPS) {
            wheel.setAngularVelocity(WorldConstants.MAX_ANGULAR_SPEED_RADPS);
        } else if (w < -WorldConstants.MAX_ANGULAR_SPEED_RADPS) {
            wheel.setAngularVelocity(-WorldConstants.MAX_ANGULAR_SPEED_RADPS);
        }
    }

    private void resolveEndState() {
        float xPx = wheel.getPosition().x * WorldConstants.PPM;
        float yPx = wheel.getPosition().y * WorldConstants.PPM;
        if (xPx >= terrain.finishXPx) {
            state = State.WON;
        } else if (yPx < terrain.lowerBoundYPx) {
            state = State.LOST;
        }
    }

    public boolean isGrounded() {
        return wheelContacts > 0;
    }

    public State getState() {
        return state;
    }

    public float getElapsedSeconds() {
        return elapsedSeconds;
    }

    /** Current linear speed magnitude in m/s (direction-independent), for the HUD. */
    public float getSpeedMps() {
        return wheel.getLinearVelocity().len();
    }

    public float getWheelXPx() {
        return wheel.getPosition().x * WorldConstants.PPM;
    }

    public float getWheelYPx() {
        return wheel.getPosition().y * WorldConstants.PPM;
    }

    public float getWheelAngleRad() {
        return wheel.getAngle();
    }

    public TerrainData getTerrain() {
        return terrain;
    }

    public void dispose() {
        world.dispose();
    }

    /** Counts contacts that involve the wheel so drive torque is ground-only. */
    private final class GroundContactListener implements ContactListener {
        @Override
        public void beginContact(Contact contact) {
            if (involvesWheel(contact)) {
                wheelContacts++;
            }
        }

        @Override
        public void endContact(Contact contact) {
            if (involvesWheel(contact)) {
                wheelContacts = Math.max(0, wheelContacts - 1);
            }
        }

        @Override
        public void preSolve(Contact contact, Manifold oldManifold) {
        }

        @Override
        public void postSolve(Contact contact, ContactImpulse impulse) {
        }

        private boolean involvesWheel(Contact contact) {
            return isWheel(contact.getFixtureA()) || isWheel(contact.getFixtureB());
        }

        private boolean isWheel(Fixture fixture) {
            return BodyFactory.WHEEL.equals(fixture.getUserData());
        }
    }
}
