package com.micro1.leap;

import com.badlogic.gdx.math.Rectangle;

/**
 * Static level geometry for Leap: the 3200x560 world holds ten solid platform
 * columns and one goal object. Every platform extends from gameplay y=0 up to
 * its top height (no floating platforms). All coordinates are bottom-left, in
 * gameplay-world space, taken verbatim from the task spec.
 */
public class Level {

    public final Rectangle[] platforms;
    public final Rectangle goal;

    public Level() {
        platforms = new Rectangle[] {
            new Rectangle(0f,    0f, 400f, 80f),   // 1  start    x 0..400,    top 80
            new Rectangle(480f,  0f, 240f, 80f),   // 2           x 480..720,  top 80
            new Rectangle(800f,  0f, 200f, 160f),  // 3           x 800..1000, top 160
            new Rectangle(1080f, 0f, 200f, 160f),  // 4           x 1080..1280,top 160
            new Rectangle(1380f, 0f, 240f, 240f),  // 5           x 1380..1620,top 240
            new Rectangle(1720f, 0f, 200f, 240f),  // 6           x 1720..1920,top 240
            new Rectangle(2020f, 0f, 200f, 320f),  // 7           x 2020..2220,top 320
            new Rectangle(2320f, 0f, 240f, 320f),  // 8           x 2320..2560,top 320
            new Rectangle(2660f, 0f, 200f, 400f),  // 9           x 2660..2860,top 400
            new Rectangle(2960f, 0f, 240f, 400f),  // 10 goal     x 2960..3200,top 400
        };
        // Goal object: yellow 32x48 on Platform 10, bottom-left (3000, 400).
        goal = new Rectangle(3000f, 400f, 32f, 48f);
    }
}
