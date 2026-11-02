package com.micro1.wreckingballpendulum;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.Box2D;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.physics.box2d.joints.DistanceJoint;
import com.badlogic.gdx.utils.GdxNativesLoader;

public class WreckingBallWorld {

    public static final float PPM = WorldConstants.PPM;

    public static final float SCREEN_WIDTH_PX = WorldConstants.SCREEN_WIDTH_PX;
    public static final float SCREEN_HEIGHT_PX = WorldConstants.SCREEN_HEIGHT_PX;

    private static final float FIXED_DT = 1f / 60f;
    private static final int MAX_STEPS_PER_FRAME = 5;
    private static final int VELOCITY_ITERATIONS = 6;
    private static final int POSITION_ITERATIONS = 2;

    public enum State {
        ATTACHED, RELEASED, WON
    }

    private final World world;
    private final BodyFactory bodyFactory;
    private final Body boomBody;
    private final Body blockBody;
    private Body ballBody;
    private DistanceJoint ropeJoint;

    private State state;
    private float accumulator;
    private float ballRestTimer;
    private float blockRestTimer;
    private float winTimer;

    private final Vector2 aabbMin = new Vector2();
    private final Vector2 aabbMax = new Vector2();

    public WreckingBallWorld() {

        GdxNativesLoader.load();
        Box2D.init();
        world = new World(new Vector2(0f, WorldConstants.GRAVITY_MPS2), true);
        bodyFactory = new BodyFactory(world);
        bodyFactory.createFloor();
        boomBody = bodyFactory.createBoom();
        blockBody = bodyFactory.createBlock();
        ballBody = bodyFactory.createBall();
        ropeJoint = bodyFactory.attachRope(boomBody, ballBody);
        state = State.ATTACHED;
    }

    public void update(float delta, boolean leftHeld, boolean rightHeld, boolean releasePressed) {
        if (state == State.ATTACHED && releasePressed) {
            releaseBall();
        }
        accumulator += delta;
        int steps = 0;
        while (accumulator >= FIXED_DT && steps < MAX_STEPS_PER_FRAME) {
            stepPhysics(leftHeld, rightHeld);
            accumulator -= FIXED_DT;
            steps++;
        }
    }

    private void stepPhysics(boolean leftHeld, boolean rightHeld) {
        boolean inputEnabled = state == State.ATTACHED;
        driveBoom(inputEnabled && leftHeld, inputEnabled && rightHeld);
        world.step(FIXED_DT, VELOCITY_ITERATIONS, POSITION_ITERATIONS);

        if (state == State.RELEASED) {
            updateReleased();
        } else if (state == State.WON) {
            updateWon();
        }
    }

    private void driveBoom(boolean leftHeld, boolean rightHeld) {
        float vx = 0f;
        if (leftHeld && !rightHeld) {
            vx = -WorldConstants.BOOM_SPEED_MPS;
        } else if (rightHeld && !leftHeld) {
            vx = WorldConstants.BOOM_SPEED_MPS;
        }
        float currentX = boomBody.getPosition().x;
        float projected = currentX + vx * FIXED_DT;
        if (projected < WorldConstants.BOOM_MIN_X_M) {
            vx = (WorldConstants.BOOM_MIN_X_M - currentX) / FIXED_DT;
        } else if (projected > WorldConstants.BOOM_MAX_X_M) {
            vx = (WorldConstants.BOOM_MAX_X_M - currentX) / FIXED_DT;
        }
        boomBody.setLinearVelocity(vx, 0f);
    }

    private void releaseBall() {
        world.destroyJoint(ropeJoint);
        ropeJoint = null;
        state = State.RELEASED;
        ballRestTimer = 0f;
        blockRestTimer = 0f;
    }

    private void updateReleased() {
        ballRestTimer = isAtRest(ballBody) ? ballRestTimer + FIXED_DT : 0f;
        blockRestTimer = isAtRest(blockBody) ? blockRestTimer + FIXED_DT : 0f;

        if (isFullyOffScreen(blockBody)) {
            state = State.WON;
            winTimer = 0f;
            return;
        }

        boolean ballDone = ballRestTimer >= WorldConstants.REST_DURATION_S || isFullyOffScreen(ballBody);
        boolean blockDone = blockRestTimer >= WorldConstants.REST_DURATION_S;
        if (ballDone && blockDone) {
            resetForNextThrow(false);
        }
    }

    private void updateWon() {
        winTimer += FIXED_DT;
        if (winTimer >= WorldConstants.WIN_RESET_DELAY_S) {
            resetForNextThrow(true);
        }
    }

    private void resetForNextThrow(boolean restoreBlock) {
        world.destroyBody(ballBody);
        boomBody.setTransform(WorldConstants.BOOM_HOME_X_M, WorldConstants.BOOM_Y_M, 0f);
        boomBody.setLinearVelocity(0f, 0f);
        ballBody = bodyFactory.createBall();
        ropeJoint = bodyFactory.attachRope(boomBody, ballBody);
        if (restoreBlock) {
            blockBody.setTransform(WorldConstants.BLOCK_HOME_X_M, WorldConstants.BLOCK_HOME_Y_M, 0f);
            blockBody.setLinearVelocity(0f, 0f);
            blockBody.setAngularVelocity(0f);
        }
        ballRestTimer = 0f;
        blockRestTimer = 0f;
        winTimer = 0f;
        state = State.ATTACHED;
    }

    private boolean isAtRest(Body body) {
        return body.getLinearVelocity().len() < WorldConstants.REST_LINEAR_MPS
                && Math.abs(body.getAngularVelocity()) < WorldConstants.REST_ANGULAR_RADPS;
    }

    private boolean isFullyOffScreen(Body body) {
        return BodyBounds.isFullyOffScreen(body, aabbMin, aabbMax);
    }

    public State getState() {
        return state;
    }

    public boolean isRopeAttached() {
        return ropeJoint != null;
    }

    public float getBoomXPx() {
        return boomBody.getPosition().x * PPM;
    }

    public float getBoomTopYPx() {
        return WorldConstants.BOOM_TOP_Y_PX;
    }

    public float getBoomBottomYPx() {
        return WorldConstants.BOOM_BOTTOM_Y_PX;
    }

    public static float getFloorHeightPx() {
        return WorldConstants.FLOOR_HEIGHT_PX;
    }

    public float getBallCenterXPx() {
        return ballBody.getPosition().x * PPM;
    }

    public float getBallCenterYPx() {
        return ballBody.getPosition().y * PPM;
    }

    public float getBallTopYPx() {
        return getBallCenterYPx() + WorldConstants.BALL_RADIUS_PX;
    }

    public static float getBallRadiusPx() {
        return WorldConstants.BALL_RADIUS_PX;
    }

    public float getBlockCenterXPx() {
        return blockBody.getPosition().x * PPM;
    }

    public float getBlockCenterYPx() {
        return blockBody.getPosition().y * PPM;
    }

    public float getBlockAngleDeg() {
        return blockBody.getAngle() * MathUtils.radiansToDegrees;
    }

    public static float getBlockSizePx() {
        return WorldConstants.BLOCK_SIZE_PX;
    }

    public void dispose() {
        world.dispose();
    }
}
