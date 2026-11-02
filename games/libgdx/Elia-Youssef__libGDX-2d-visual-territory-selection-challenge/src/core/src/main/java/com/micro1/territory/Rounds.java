package com.micro1.territory;

import com.badlogic.gdx.graphics.Color;

/**
 * Builds the four rounds from the provided polygon data (polygon_points_reference.png), in the
 * 100x60 coordinate space (origin top-left, y increasing downward). Areas are computed by the
 * shoelace formula, so the "largest" answer is derived from the real geometry rather than the
 * (inconsistent) labeled areas - matching game_states_reference (Round 1 = Blue ~25.8%).
 *
 * The Round 4 polygon reference says the X meets at (50,30), but the supplied PNG's actual black
 * junction is near (47.5,29.8). The playable polygons follow the supplied raster so hit detection,
 * highlighting, and the visible areas agree; Green is therefore the real largest territory.
 *
 * Colors match the shape PNGs: Territory 1 purple, 2 green, 3 yellow, 4 blue.
 */
public final class Rounds {

    private Rounds() {
    }

    public static final Color PURPLE = new Color(198f / 255f, 163f / 255f, 237f / 255f, 1f);
    public static final Color GREEN  = new Color(183f / 255f, 221f / 255f, 185f / 255f, 1f);
    public static final Color YELLOW = new Color(242f / 255f, 217f / 255f, 133f / 255f, 1f);
    public static final Color BLUE   = new Color(163f / 255f, 200f / 255f, 238f / 255f, 1f);

    private static Territory t(int idx, String name, Color c, float... poly) {
        return new Territory(idx, name, c, poly);
    }

    public static Round[] build() {
        return new Round[]{
            new Round(1, "shape1.png", new Territory[]{
                t(0, "Purple", PURPLE, 0, 0, 48, 0, 52, 30, 0, 29),
                t(1, "Green",  GREEN,  48, 0, 100, 0, 100, 28, 52, 30),
                t(2, "Yellow", YELLOW, 0, 29, 52, 30, 48, 60, 0, 60),
                t(3, "Blue",   BLUE,   52, 30, 100, 28, 100, 60, 48, 60),
            }),
            new Round(2, "shape2.png", new Territory[]{
                t(0, "Purple", PURPLE, 0, 0, 48, 0, 47, 26, 0, 29),
                t(1, "Green",  GREEN,  48, 0, 100, 0, 100, 33, 52, 30, 47, 26),
                t(2, "Yellow", YELLOW, 0, 29, 47, 26, 52, 30, 48, 60, 0, 60),
                t(3, "Blue",   BLUE,   52, 30, 100, 33, 100, 60, 48, 60),
            }),
            new Round(3, "shape3.png", new Territory[]{
                t(0, "Purple", PURPLE, 0, 0, 47, 0, 47, 22, 56, 22, 56, 30, 32, 30, 32, 25, 0, 27),
                t(1, "Green",  GREEN,  47, 0, 100, 0, 100, 26, 82, 26, 82, 30, 56, 30, 56, 22, 47, 22),
                t(2, "Yellow", YELLOW, 0, 27, 32, 25, 32, 30, 52, 30, 48, 60, 0, 60),
                t(3, "Blue",   BLUE,   52, 30, 82, 30, 82, 26, 100, 26, 100, 60, 48, 60),
            }),
            new Round(4, "shape4.png", new Territory[]{
                t(0, "Purple", PURPLE, 0, 0, 100, 0, 47.5f, 29.8f),
                t(1, "Green",  GREEN,  100, 0, 100, 60, 47.5f, 29.8f),
                t(2, "Yellow", YELLOW, 0, 0, 47.5f, 29.8f, 0, 60),
                t(3, "Blue",   BLUE,   0, 60, 47.5f, 29.8f, 100, 60),
            }),
        };
    }
}
