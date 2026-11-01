package com.micro1.runningwheel;

/**
 * Shared dimensions, physics values, terrain-generation parameters, and pixel/meter
 * conversions for Running Wheel. All layout values are authored in pixels for the fixed
 * 800x600 window; Box2D bodies are built in meters via {@link #PPM}. One place to tune.
 */
public final class WorldConstants {

    /** Pixels per meter: Box2D simulates in meters, everything is drawn in pixels. */
    public static final float PPM = 100f;

    // Fixed window / viewport.
    public static final float WINDOW_WIDTH_PX = 800f;
    public static final float WINDOW_HEIGHT_PX = 600f;

    // The scrolling world. At least 5x the window width is a hard requirement; 6000 is 7.5x.
    public static final float WORLD_WIDTH_PX = 6000f;
    /** Crossing below this world y (in px) is the loss condition (falling into a chasm). */
    public static final float LOWER_BOUND_Y_PX = 0f;
    /** Horizontal position of the finish; reaching it is the win condition. */
    public static final float FINISH_X_PX = WORLD_WIDTH_PX - 200f;

    // The wheel (a circular dynamic body). Radius must stay in [15, 80] px per the rubric.
    public static final float WHEEL_RADIUS_PX = 28f;
    public static final float WHEEL_START_X_PX = 130f;
    public static final float WHEEL_DENSITY = 8f;
    public static final float WHEEL_FRICTION = 0.9f;
    public static final float WHEEL_RESTITUTION = 0.15f;

    /** Torque magnitude applied while a drive key is held and the wheel is grounded. */
    public static final float DRIVE_TORQUE = 11f;
    /** Angular-speed cap (rad/s) so the wheel reaches a sane top speed instead of spinning up forever. */
    public static final float MAX_ANGULAR_SPEED_RADPS = 50f;

    // Static terrain surface.
    public static final float GROUND_FRICTION = 0.9f;
    public static final float GROUND_RESTITUTION = 0.05f;

    /** Constant downward gravity (m/s^2), applied by the Box2D world every step. */
    public static final float GRAVITY_MPS2 = -9.8f;

    // Terrain generation (all px). The surface is a smooth sampled height curve with a few
    // launch ramps and jumpable gaps; start and finish stretches are flattened.
    public static final float GROUND_SAMPLE_DX_PX = 30f;
    public static final float GROUND_MIN_Y_PX = 120f;
    public static final float GROUND_MAX_Y_PX = 330f;
    public static final float START_ZONE_PX = 700f;
    public static final float FINISH_ZONE_PX = 700f;
    public static final float START_GROUND_Y_PX = 190f;
    public static final float FINISH_GROUND_Y_PX = 175f;
    /** Y the terrain fill is drawn down to (below the visible world) so no white shows under hills. */
    public static final float FILL_BOTTOM_Y_PX = -400f;

    public static final int MIN_GAPS = 2;
    public static final int MAX_GAPS = 3;
    public static final float GAP_MIN_PX = 100f;
    public static final float GAP_MAX_PX = 135f;
    /** Flat run before a gap so the wheel arrives at speed (no uphill to bleed momentum). */
    public static final float FLAT_APPROACH_PX = 320f;
    /** Length + height of the small edge kicker: a slight upward launch that cannot stall a moving wheel. */
    public static final float KICK_RUN_PX = 90f;
    public static final float KICK_RISE_PX = 24f;
    /** The landing sits this much below the launch edge, so the jump is a drop across the gap. */
    public static final float LAND_DROP_MIN_PX = 45f;
    public static final float LAND_DROP_MAX_PX = 85f;

    // Finish flag + HUD.
    public static final float FINISH_POLE_HEIGHT_PX = 150f;
    public static final float HUD_PANEL_HEIGHT_PX = 34f;

    // Meter conversions used when building Box2D bodies.
    public static final float WHEEL_RADIUS_M = WHEEL_RADIUS_PX / PPM;

    public static float toM(float px) {
        return px / PPM;
    }

    private WorldConstants() {
    }
}
