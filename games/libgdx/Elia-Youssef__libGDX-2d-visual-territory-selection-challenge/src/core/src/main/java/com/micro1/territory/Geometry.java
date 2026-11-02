package com.micro1.territory;

import com.badlogic.gdx.math.Intersector;

/**
 * Pure geometry helpers (no GL). Polygon vertices are flattened {x0,y0,x1,y1,...} in the
 * 100x60 territory coordinate space (origin top-left, y increasing downward).
 */
public final class Geometry {

    private static final float EDGE_EPSILON = 0.0001f;

    private Geometry() {
    }

    /** Signed-area (shoelace) magnitude of a simple polygon. Works for convex and concave. */
    public static float shoelace(float[] poly) {
        float sum = 0f;
        int n = poly.length / 2;
        for (int i = 0; i < n; i++) {
            int j = (i + 1) % n;
            sum += poly[2 * i] * poly[2 * j + 1] - poly[2 * j] * poly[2 * i + 1];
        }
        return Math.abs(sum) / 2f;
    }

    /**
     * True if (x,y) is inside or on the boundary of the polygon. The explicit segment check makes
     * clicks on outer edges and corners selectable; libGDX's ray-cast alone excludes some of them.
     */
    public static boolean contains(float[] poly, float x, float y) {
        int points = poly.length / 2;
        for (int i = 0; i < points; i++) {
            int j = (i + 1) % points;
            float x1 = poly[2 * i];
            float y1 = poly[2 * i + 1];
            float x2 = poly[2 * j];
            float y2 = poly[2 * j + 1];
            float dx = x2 - x1;
            float dy = y2 - y1;
            float cross = (x - x1) * dy - (y - y1) * dx;
            float tolerance = EDGE_EPSILON * Math.max(1f, Math.abs(dx) + Math.abs(dy));
            if (Math.abs(cross) <= tolerance
                    && x >= Math.min(x1, x2) - EDGE_EPSILON
                    && x <= Math.max(x1, x2) + EDGE_EPSILON
                    && y >= Math.min(y1, y2) - EDGE_EPSILON
                    && y <= Math.max(y1, y2) + EDGE_EPSILON) {
                return true;
            }
        }
        return Intersector.isPointInPolygon(poly, 0, poly.length, x, y);
    }
}
