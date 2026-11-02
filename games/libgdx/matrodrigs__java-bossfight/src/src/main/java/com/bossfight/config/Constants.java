package com.bossfight.config;

public final class Constants {
    public static final String GAME_TITLE = "Fúria Botânica";

    public static final int WINDOW_WIDTH = 1280;
    public static final int WINDOW_HEIGHT = 720;
    public static final int TARGET_FPS = 60;

    public static final float WORLD_WIDTH = 1280f;
    public static final float WORLD_HEIGHT = 720f;
    public static final float ARENA_LEFT = 60f;
    public static final float ARENA_RIGHT = WORLD_WIDTH - 60f;
    public static final float FLOOR_Y = 92f;
    public static final float GRAVITY = -1900f;

    public static final float PLAYER_WIDTH = 46f;
    public static final float PLAYER_HEIGHT = 82f;
    public static final float PLAYER_START_X = 170f;
    public static final float PLAYER_START_Y = FLOOR_Y;
    public static final float PLAYER_SPEED = 340f;
    public static final float PLAYER_JUMP_SPEED = 780f;
    public static final float PLAYER_DASH_SPEED = 960f;
    public static final float PLAYER_DASH_DURATION = 0.14f;
    public static final float PLAYER_DASH_COOLDOWN = 0.55f;
    public static final float PLAYER_SHOOT_COOLDOWN = 0.20f;
    public static final float PLAYER_INVULNERABILITY_DURATION = 0.95f;
    public static final float PLAYER_SPECIAL_MAX = 100f;
    public static final float PLAYER_SPECIAL_HIT_CHARGE = 2.5f;
    public static final float PLAYER_SPECIAL_COOLDOWN = 0.45f;
    public static final int PLAYER_MAX_HEALTH = 5;

    public static final float BOSS_WIDTH = 170f;
    public static final float BOSS_HEIGHT = 230f;
    public static final float BOSS_START_X = 930f;
    public static final float BOSS_START_Y = FLOOR_Y;
    public static final int BOSS_MAX_HEALTH = 400;

    public static final float PLAYER_PROJECTILE_WIDTH = 22f;
    public static final float PLAYER_PROJECTILE_HEIGHT = 10f;
    public static final float PLAYER_PROJECTILE_SPEED = 760f;
    public static final int PLAYER_PROJECTILE_DAMAGE = 2;
    public static final float PLAYER_SPECIAL_WIDTH = 58f;
    public static final float PLAYER_SPECIAL_HEIGHT = 22f;
    public static final float PLAYER_SPECIAL_SPEED = 920f;
    public static final int PLAYER_SPECIAL_DAMAGE = 16;

    public static final float BOSS_PROJECTILE_WIDTH = 24f;
    public static final float BOSS_PROJECTILE_HEIGHT = 24f;
    public static final int BOSS_PROJECTILE_DAMAGE = 1;

    public static final float INTRO_READY_DURATION = 1.2f;
    public static final float INTRO_GO_DURATION = 1.155f;
    public static final float INTRO_TOTAL_DURATION = INTRO_READY_DURATION + INTRO_GO_DURATION;

    private Constants() {
    }
}
