package com.micro1.cookiesort;

/**
 * One of the 40 cookies. {@code homeX}/{@code homeY} is its fixed center-plate slot (from the sunflower
 * layout computed once per {@link CookieSortWorld#reset()}); {@code x}/{@code y} is its current rendered
 * position (equal to home while on the center plate, following the pointer while dragged, or a slot on a
 * corner plate once placed). {@code placedOn} is {@code null} until a successful placement.
 */
public class Cookie {
    public final int id;
    public final CookieType type;
    public final float homeX;
    public final float homeY;

    public float x;
    public float y;
    public Corner placedOn;

    public Cookie(int id, CookieType type, float homeX, float homeY) {
        this.id = id;
        this.type = type;
        this.homeX = homeX;
        this.homeY = homeY;
        this.x = homeX;
        this.y = homeY;
        this.placedOn = null;
    }

    public boolean isOnCenterPlate() {
        return placedOn == null;
    }

    /** Snaps the cookie back to its fixed center-plate slot (a rejected or cancelled drop). */
    public void returnHome() {
        this.x = homeX;
        this.y = homeY;
        this.placedOn = null;
    }
}
