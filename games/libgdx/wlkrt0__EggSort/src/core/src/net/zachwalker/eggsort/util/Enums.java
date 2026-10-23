package net.zachwalker.eggsort.util;


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

    public enum EggType {
        WHITE,
        BROWN,
        CHICK,
        POWERUP
    }

    public enum EggState {
        CHUTE,
        RAMP,
        FALLING,
        CAUGHT,
        MISSED
    }

    public enum ChickenColor {
        WHITE,
        BROWN
    }

    /* IMPORTANT NOTE! The order and quantity of these enum entries is critical.
     * Must exactly align with the buckets array since .ordinal() is called as an index on the array  */
    public enum EggFellThru {
        LEFT_VALVE,
        RIGHT_VALVE,
        END
    }

}
