package com.micro1.territory;

import com.badlogic.gdx.graphics.Color;

/** One colored territory: its polygon (100x60 coord space), fill color, and computed area. */
public class Territory {

    public final int index;         // 0-3
    public final String colorName;  // "Purple","Green","Yellow","Blue"
    public final Color color;
    public final float[] polygon;   // flattened x,y in 100x60 coords (origin top-left, y-down)
    public final float area;        // shoelace area in coord units

    public Territory(int index, String colorName, Color color, float[] polygon) {
        this.index = index;
        this.colorName = colorName;
        this.color = color;
        this.polygon = polygon;
        this.area = Geometry.shoelace(polygon);
    }
}
