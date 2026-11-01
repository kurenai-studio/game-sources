package com.micro1.shadowclash;

/**
 * Shared world constants (logical units = the 1100x900 window, origin bottom-left, y up).
 * Kept in one place so {@link Fighter}, {@link ClashWorld} and the render layer agree on the
 * arena geometry, speeds and timings.
 */
public final class K {
    private K() {}

    public static final float WORLD_W = 1100f, WORLD_H = 900f;
    public static final float GROUND = 150f;            // feet y for a standing fighter
    public static final float ARENA_LEFT = 90f, ARENA_RIGHT = 1010f; // body-centre clamp range

    public static final float BODY_W = 84f, BODY_H = 210f, CROUCH_H = 130f;

    public static final float WALK = 185f, RUN = 355f;
    public static final float BACKDASH_SPEED = 440f, BACKDASH_TIME = 0.30f;
    public static final float JUMP_V = 660f, GRAVITY = -1680f, LAUNCH_V = 780f;

    public static final float TORSO = 128f;             // projectile / mid-hit height above feet

    public static final int MAX_HP = 100;
    public static final float UNLOCK_HP = 75f;          // specials unlock strictly below this

    public static final float SLOW_SCALE = 0.35f;       // game speed during slow motion
    public static final float SPECIAL_SLOWMO = 0.90f;   // real seconds of slow-mo per special
    public static final float KO_SLOWMO = 1.70f;        // real seconds of slow-mo on the finish

    public static final float READY_TIME = 3.0f;        // "GET READY"
    public static final float FIGHT_TIME = 1.0f;        // "FIGHT" banner before COMBAT

    public static final float PROJECTILE_SPEED = 560f;
}
