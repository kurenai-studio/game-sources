package com.micro1.runningwheel;

import java.util.List;

/**
 * Plain, GL-free description of one generated course, in pixel space. Consumed twice: by
 * {@link BodyFactory} to build the static Box2D bodies, and by {@link RunningWheelApp} to draw
 * the matching visuals. Keeping it pure data lets the generator run headless in tests.
 *
 * Shape variety (rubric): {@link #groundSegments} become Box2D chains (the curved surface),
 * {@link #platforms} become box polygons (rectangles), and {@link #rampWedge} is a triangle
 * polygon. Gaps are simply the absences between consecutive ground segments.
 */
public final class TerrainData {

    /** One polyline per solid stretch of ground: {x0,y0,x1,y1,...} in px, left to right. */
    public final List<float[]> groundSegments;
    /** Floating rectangles: {centerX, centerY, halfWidth, halfHeight} in px. */
    public final List<float[]> platforms;
    /** A single triangular ramp {x0,y0,x1,y1,x2,y2} in px (CCW), or null if none. */
    public final float[] rampWedge;

    public final float startXPx;
    public final float startYPx;
    public final float finishXPx;
    public final float finishGroundYPx;
    public final float lowerBoundYPx;
    public final float worldWidthPx;

    public TerrainData(List<float[]> groundSegments, List<float[]> platforms, float[] rampWedge,
                       float startXPx, float startYPx, float finishXPx, float finishGroundYPx,
                       float lowerBoundYPx, float worldWidthPx) {
        this.groundSegments = groundSegments;
        this.platforms = platforms;
        this.rampWedge = rampWedge;
        this.startXPx = startXPx;
        this.startYPx = startYPx;
        this.finishXPx = finishXPx;
        this.finishGroundYPx = finishGroundYPx;
        this.lowerBoundYPx = lowerBoundYPx;
        this.worldWidthPx = worldWidthPx;
    }
}
