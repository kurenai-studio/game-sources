package com.veilfall.game.player;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Preferences;

public final class ControlBindings {
    private static final Preferences PREFS = Gdx.app.getPreferences("veilfall-controls");

    private ControlBindings() { }

    public static int get(String action) {
        return PREFS.getInteger(action, defaultKey(action));
    }

    public static void set(String action, int keyCode) {
        PREFS.putInteger(action, keyCode);
        PREFS.flush();
    }

    public static String display(String action) {
        return Input.Keys.toString(get(action));
    }

    private static int defaultKey(String action) {
        return switch (action) {
            case "up" -> Input.Keys.W;
            case "down" -> Input.Keys.S;
            case "left" -> Input.Keys.A;
            case "right" -> Input.Keys.D;
            case "ability_q" -> Input.Keys.Q;
            case "ability_e" -> Input.Keys.E;
            case "ability_r" -> Input.Keys.R;
            case "dodge" -> Input.Keys.SPACE;
            default -> Input.Keys.UNKNOWN;
        };
    }
}
