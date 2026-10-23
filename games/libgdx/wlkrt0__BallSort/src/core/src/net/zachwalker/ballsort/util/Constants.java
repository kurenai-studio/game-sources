package net.zachwalker.ballsort.util;

import com.badlogic.gdx.graphics.Color;


public final class Constants {
    public static final String LOG_TAG = "BallSort";

    public static final String PREFERENCES_FILE_NAME = "net.zachwalker.ballsort.preferences";
    public static final String PREF_KEY_HIGH_SCORE = "highscore";
    public static final String PREF_KEY_HIGH_LEVEL = "highlevel";

    public static final int WORLD_WIDTH = 444;
    public static final int WORLD_HEIGHT = 250;
    public static final Color BACKGROUND_COLOR = Color.BLACK;

    public static final float GRAVITY = 7.0f;

    public static final float LEVEL_START_DELAY = 10.0f;
    public static final float POWERUP_DURATION = 13.5f;

    public static final float BALL_SIZE = 10.0f;
    public static final float BALL_SPEED = 40.0f;
    public static final double BALL_SPAWN_INTERVAL_MIN = 0.5f;

    public static final float CHUTE_WIDTH = BALL_SIZE * 2.0f;
    public static final float CHUTE_HEIGHT = 200.0f;
    public static final float CHUTE_MARGIN = 20.0f;
    public static final Color CHUTE_COLOR = Color.GRAY;

    public static final float RAMP_WIDTH = 100.0f;

    public static final float VALVE_WIDTH = BALL_SIZE * 2.0f;
    public static final float VALVE_HEIGHT = VALVE_WIDTH / 4.0f;
    public static final Color VALVE_COLOR = Color.GREEN;
    public static final float VALVE_ROTATION = 270.0f;

    public static final float BUCKET_WIDTH = BALL_SIZE * 4.0f;
    public static final float BUCKET_HEIGHT = BALL_SIZE * 4.0f;
    public static final Color BUCKET_LEFT_COLOR = Color.RED;
    public static final Color BUCKET_MIDDLE_COLOR = Color.YELLOW;
    public static final Color BUCKET_RIGHT_COLOR = Color.BLUE;
    public static final int BUCKET_GOAL_PER_LEVEL = 2;

    public static final String SCORE_LABEL = "";
    public static final String HIGH_SCORE_LABEL = "";
    public static final String LEVEL_LABEL = "LEVEL ";
    public static final String COMBO_LABEL = "x";
    public static final float LABEL_MARGIN = 10.0f;

    public static final Color TOUCHTARGET_COLOR = Color.GREEN;

    public static final String SOUND_NEWBALL = "newball.wav";
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

}
