package net.zachwalker.ballsort.util;


public class Enums {

    public enum GameState {
        GOTO_NEXT_LEVEL,
        STARTING_NEXT_LEVEL,
        PLAYING_NORMAL,
        GAME_OVER
    }

    public enum ValveState {
        OPEN,
        CLOSED
    }

    public enum BallType {
        RED,
        YELLOW,
        BLUE,
        POWERUP
    }

    public enum BallState {
        CHUTE,
        RAMP,
        FALLING,
        CAUGHT,
        MISSED
    }

    /* IMPORTANT NOTE! The order and quantity of these enum entries is critical.
     * Must exactly align with the buckets array since .ordinal() is called as an index on the array  */
    public enum BallFellThru {
        LEFT_VALVE,
        RIGHT_VALVE,
        END
    }

}
