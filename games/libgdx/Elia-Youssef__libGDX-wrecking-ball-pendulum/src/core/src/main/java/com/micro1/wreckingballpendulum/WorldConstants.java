package com.micro1.wreckingballpendulum;

/** Shared dimensions, physics values, and meter-space conversions for the fixed scene. */
final class WorldConstants {

    static final float PPM = 100f;

    static final float SCREEN_WIDTH_PX = 900f;
    static final float SCREEN_HEIGHT_PX = 500f;

    static final float FLOOR_HEIGHT_PX = 30f;

    static final float BOOM_TOP_Y_PX = 500f;
    static final float BOOM_BOTTOM_Y_PX = 350f;
    static final float BOOM_HOME_X_PX = 365f;
    static final float BOOM_TRAVEL_PX = 65f;
    static final float BOOM_MIN_X_PX = BOOM_HOME_X_PX - BOOM_TRAVEL_PX;
    static final float BOOM_MAX_X_PX = BOOM_HOME_X_PX + BOOM_TRAVEL_PX;
    static final float BOOM_SPEED_MPS = 0.5f;

    static final float ROPE_LENGTH_PX = 235f;

    static final float BALL_RADIUS_PX = 25f;
    static final float BALL_DENSITY = 7200f;
    static final float BALL_FRICTION = 0.3f;
    static final float BALL_RESTITUTION = 0.25f;

    static final float BLOCK_SIZE_PX = 85f;
    static final float BLOCK_HOME_X_PX = 680f;
    static final float BLOCK_DENSITY = 500f;
    static final float BLOCK_FRICTION = 0.5f;
    static final float BLOCK_RESTITUTION = 0.1f;

    static final float FLOOR_FRICTION = 0.5f;
    static final float FLOOR_RESTITUTION = 0f;

    static final float GRAVITY_MPS2 = -9.8f;

    static final float REST_LINEAR_MPS = 0.05f;
    static final float REST_ANGULAR_RADPS = 0.05f;
    static final float REST_DURATION_S = 0.5f;
    static final float WIN_RESET_DELAY_S = 2.0f;

    static final float BOOM_Y_M = BOOM_BOTTOM_Y_PX / PPM;
    static final float BOOM_HOME_X_M = BOOM_HOME_X_PX / PPM;
    static final float BOOM_MIN_X_M = BOOM_MIN_X_PX / PPM;
    static final float BOOM_MAX_X_M = BOOM_MAX_X_PX / PPM;
    static final float ROPE_LENGTH_M = ROPE_LENGTH_PX / PPM;
    static final float BALL_RADIUS_M = BALL_RADIUS_PX / PPM;
    static final float BALL_HOME_Y_M = (BOOM_BOTTOM_Y_PX - ROPE_LENGTH_PX - BALL_RADIUS_PX) / PPM;
    static final float BLOCK_HALF_SIZE_M = (BLOCK_SIZE_PX / 2f) / PPM;
    static final float BLOCK_HOME_X_M = BLOCK_HOME_X_PX / PPM;
    static final float BLOCK_HOME_Y_M = (FLOOR_HEIGHT_PX / PPM) + BLOCK_HALF_SIZE_M;
    static final float FLOOR_HALF_WIDTH_M = (SCREEN_WIDTH_PX / 2f) / PPM;
    static final float FLOOR_HALF_HEIGHT_M = (FLOOR_HEIGHT_PX / 2f) / PPM;
    static final float SCREEN_WIDTH_M = SCREEN_WIDTH_PX / PPM;
    static final float SCREEN_HEIGHT_M = SCREEN_HEIGHT_PX / PPM;

    private WorldConstants() {
    }
}
