package net.zachwalker.eggsort.util;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.Vector2;

public final class Constants {

    public static final String LOG_TAG = "EggSort";

    public static final String PREFERENCES_FILE_NAME = "net.zachwalker.eggsort.preferences";
    public static final String PREF_KEY_HIGH_SCORE = "highscore";
    public static final String PREF_KEY_HIGH_LEVEL = "highlevel";

    public static final int WORLD_WIDTH = 884;
    public static final int WORLD_HEIGHT = 502;
    public static final Color BACKGROUND_COLOR = Color.BLACK;

    public static final float GRAVITY = 14.0f;

    public static final float LEVEL_START_DELAY = 8.0f;
    public static final float POWERUP_DURATION = 9.0f;

    public static final float EGG_SIZE = 13.0f;
    public static final float EGG_SPEED = 80.0f;
    public static final Vector2 EGG_SPAWN = new Vector2(110.0f, 42.0f);
    public static final double EGG_SPAWN_INTERVAL_MIN = 0.5f;

    public static final float CHUTE_HEIGHT = 404.0f;

    public static final float RAMP_END = 747.0f;

    public static final Vector2 BUTTON_ROTATE_LEFT_POSITION = new Vector2(283.0f, 36.0f);
    public static final Vector2 BUTTON_ROTATE_RIGHT_POSITION = new Vector2(522.0f, 36.0f);
    public static final Vector2 BUTTON_GOTO_LEVEL_POSITION = new Vector2(822.0f, 363.0f);
    public static final Vector2 BUTTON_MUTE_POSITION = new Vector2(822.0f, 295.0f);

    public static final Vector2 VALVE_LEFT_POSITION = new Vector2(320.0f, 353.0f);
    public static final Vector2 VALVE_RIGHT_POSITION = new Vector2(561.0f, 353.0f);
    public static final float VALVE_WIDTH = EGG_SIZE * 2.0f;

    public static final Vector2 CHICKEN_WHITE_POSITION = new Vector2(10.0f, 124.0f);
    public static final Vector2 CHICKEN_BROWN_POSITION = new Vector2(10.0f, 32.0f);

    public static final Vector2 BUCKET_LEFT_POSITION = new Vector2(280.0f, 189.0f);
    public static final Vector2 BUCKETS_FILLED_LEFT_POSITION = new Vector2(309.0f, 196.0f);
    public static final Vector2 BUCKET_MIDDLE_POSITION = new Vector2(520.0f, 189.0f);
    public static final Vector2 BUCKETS_FILLED_MIDDLE_POSITION = new Vector2(549.0f, 196.0f);
    public static final Vector2 BUCKET_RIGHT_POSITION = new Vector2(732.0f, 136.0f);
    public static final Vector2 BUCKETS_FILLED_RIGHT_POSITION = new Vector2(726.0f, 143.0f);
    public static final float BUCKET_TOP = 210f;
    public static final int BUCKET_GOAL_PER_LEVEL = 2;

    public static final String LABEL_FONT = "segoe_wp_black";
    public static final Color LABEL_COLOR = Color.WHITE;
    public static final float LABEL_MARGIN = 13.0f;
    public static final float LABEL_SCORE_X = 700.0f;
    public static final String LEVEL_LABEL = "LEVEL ";
    public static final String LABEL_COMBO = "x";

    public static final String SOUND_FARM_AMBIENCE = "farm_ambience.mp3";
    public static final String SOUND_NEW_EGG = "newegg.wav";
    public static final String SOUND_VALVE = "valve.wav";
    public static final String SOUND_MISSED = "missed.wav";
    public static final String SOUND_GAME_OVER = "gameover.wav";
    public static final String SOUND_FULL = "full.wav";
    public static final String SOUND_NEW_LEVEL = "newlevel.wav";
    public static final String SOUND_POWERUP = "powerup.wav";
    public static final String SOUND_BUTTON = "button.wav";
    public static final String SOUND_CAUGHT_PREFIX = "caught";
    public static final String SOUND_CAUGHT_SUFFIX = ".wav";
    public static final int SOUND_CAUGHT_COUNT = 16;

    public static final String PACKED_TEXTURE_ATLAS = "eggsort.pack.atlas";
    public static final String TEXTURE_BACKGROUND = "background";
    public static final String TEXTURE_BUTTON_GOTO_LEVEL = "button_goto_level";
    public static final String TEXTURE_BUTTON_MUTE = "button_mute";
    public static final String TEXTURE_BUTTON_UNMUTE = "button_unmute";
    public static final String TEXTURE_BUTTON_WHITE_DOWN = "button_white_down";
    public static final String TEXTURE_BUTTON_WHITE_RIGHT = "button_white_right";
    public static final String TEXTURE_BUTTON_BROWN_DOWN = "button_brown_down";
    public static final String TEXTURE_BUTTON_BROWN_RIGHT = "button_brown_right";
    public static final String TEXTURE_EGG_WHITE = "egg_white";
    public static final String TEXTURE_EGG_BROWN = "egg_brown";
    public static final String TEXTURE_EGG_CHICK = "egg_chick";
    public static final String TEXTURES_EGG_POWERUP = "egg_powerup";
    public static final float POWERUP_ANIMATION_DELAY = 0.08f;
    public static final String TEXTURE_VALVE_LEFT_OPEN = "valve_left_open";
    public static final String TEXTURE_VALVE_LEFT_CLOSED = "valve_left_closed";
    public static final String TEXTURE_VALVE_RIGHT_OPEN = "valve_right_open";
    public static final String TEXTURE_VALVE_RIGHT_CLOSED = "valve_right_closed";
    public static final String TEXTURES_BUCKET_LEFT = "bucket_left";
    public static final String TEXTURES_BUCKET_MIDDLE = "bucket_middle";
    public static final String TEXTURES_BUCKET_RIGHT = "bucket_right";
    public static final String TEXTURES_BUCKETS_FILLED = "buckets_filled";
    public static final String TEXTURES_BUCKETS_TO_FILL = "buckets_to_fill";
    public static final String TEXTURES_CHICKEN_WHITE = "chicken_white";
    public static final String TEXTURES_CHICKEN_BROWN = "chicken_brown";
    public static final float CHICKEN_ANIMATION_DELAY = 0.5f;
}
