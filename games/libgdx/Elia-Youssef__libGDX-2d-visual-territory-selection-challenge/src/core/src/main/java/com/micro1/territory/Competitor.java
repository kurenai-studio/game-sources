package com.micro1.territory;

import com.badlogic.gdx.graphics.Color;

/** One of the four competitors (You + three CPUs). Color is the identity color (bottom circle). */
public class Competitor {

    public final String name;
    public final Color color;
    public final boolean cpu;

    public int totalScore = 0;      // cumulative across rounds
    public int roundScore = 0;      // 0 or 1 for the current round
    public int selection = -1;      // chosen territory index (0-3), -1 = none

    public Competitor(String name, Color color, boolean cpu) {
        this.name = name;
        this.color = color;
        this.cpu = cpu;
    }
}
