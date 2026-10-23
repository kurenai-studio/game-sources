package com.mygdx.fourcats;

public class Config
{
    public static final int WORLD_SIZE_X = 600;
    public static final int WORLD_SIZE_Y = 600;

    public static final int MENU_SCREENS_SIZE_X = 400;
    public static final int MENU_SCREENS_SIZE_Y = 200;
    public static final int CAT_SIZE = 50;
    public static final int MOUSE_SIZE = 35;
    public static final int MOUSE_SPEED = 3;
    public static final int MAX_MICE = 7;
    public static  int CAT_SPEED = 0;

    public static int LENNY_MAX_BERSERK = 5 * 60;
    public static int LENNY_MAX_COOLDOWN = 5 * 60;
    public static int LENNY_BERSERK_SPEED = 12;

    public static int CICCIO_CHARGING_TIME = 10;
    public static int CICCIO_JUMPING_TIME = 10;
    public static int CICCIO_JUMP_SPEED = 20;

    public static int ARCHIE_JUMPING_SPEED = 12;

    public static int GAMELENGTH = 120;

    public static void setSpeed(CatName name)
    {
        switch (name) {
            case LENNY:
                CAT_SPEED = 3;
                break;
            case CICCIO:
                CAT_SPEED = 4;
                break;
            case ARCHIE:
                CAT_SPEED = 4;
                break;
            case MERLIN:
                CAT_SPEED = 6;
                break;
        }
        }
}
