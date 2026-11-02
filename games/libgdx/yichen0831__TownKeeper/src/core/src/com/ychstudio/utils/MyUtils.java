package com.ychstudio.utils;

import com.badlogic.gdx.math.MathUtils;

public class MyUtils {

    private MyUtils() {}
    
    public static int chooseRandom(int...choices) {
        return choices[MathUtils.random(choices.length - 1)];
    }
}
