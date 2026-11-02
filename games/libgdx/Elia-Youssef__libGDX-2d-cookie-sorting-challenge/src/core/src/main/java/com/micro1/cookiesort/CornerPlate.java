package com.micro1.cookiesort;

import java.util.ArrayList;
import java.util.List;

/** One of the four corner plates: a fixed position, an assigned type (null = unassigned), and the
 * cookies placed on it in placement order (for the small sunflower-pack draw layout). */
public class CornerPlate {
    public final Corner corner;
    public final float cx;
    public final float cy;

    public CookieType assignedType;
    public final List<Integer> placedCookieIds = new ArrayList<Integer>();

    public CornerPlate(Corner corner, float cx, float cy) {
        this.corner = corner;
        this.cx = cx;
        this.cy = cy;
        this.assignedType = null;
    }

    public boolean isAssigned() {
        return assignedType != null;
    }

    public void reset() {
        assignedType = null;
        placedCookieIds.clear();
    }
}
