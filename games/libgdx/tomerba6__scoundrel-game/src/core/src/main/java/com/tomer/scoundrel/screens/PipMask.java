package com.tomer.scoundrel.screens;

/**
 * The four suit pips as 12×12 masks.
 *
 * <p>They are rasterised from circles and triangles in a 64-unit box, scaled
 * down to 12 and thresholded at each pixel's centre. A hard test rather than coverage sampling: anti-aliasing
 * a 12px glyph would spend half its pixels on grey edges, and grey is not a
 * colour this board has.
 *
 * <p>Pure, so the shapes can be checked row by row. {@link Pips} only uploads
 * what comes out of here — at this size the geometry <em>is</em> the artwork,
 * and a shape that reads wrong reads wrong long before anyone notices which
 * curve produced it.
 */
final class PipMask {

    /** The size a pip is drawn at, and the box the geometry is scaled into. */
    static final int SIZE = 12;
    /** The 64-unit box every coordinate below is in. */
    private static final float BOX = 64f;

    /** The four suits a pip can show; monsters are clubs or spades, weapons diamonds, potions hearts. */
    enum Suit {
        /** Three discs and a stem. */
        CLUBS,
        /** A rhombus, stepped at exactly 45°. */
        DIAMONDS,
        /** Two discs over a triangle. */
        HEARTS,
        /** A triangle over two discs, and a stem. */
        SPADES
    }

    private interface Shape {
        boolean holds(float x, float y);
    }

    /** A filled disc in the 64-unit box. */
    private record Disc(float cx, float cy, float r) implements Shape {
        @Override
        public boolean holds(float x, float y) {
            float dx = x - cx;
            float dy = y - cy;
            return dx * dx + dy * dy <= r * r;
        }
    }

    /** A filled triangle in the 64-unit box. */
    private record Tri(float ax, float ay, float bx, float by, float cx, float cy)
            implements Shape {
        @Override
        public boolean holds(float x, float y) {
            float d1 = side(x, y, ax, ay, bx, by);
            float d2 = side(x, y, bx, by, cx, cy);
            float d3 = side(x, y, cx, cy, ax, ay);
            boolean negative = d1 < 0 || d2 < 0 || d3 < 0;
            boolean positive = d1 > 0 || d2 > 0 || d3 > 0;
            return !(negative && positive);
        }

        private static float side(float px, float py, float x1, float y1, float x2, float y2) {
            return (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2);
        }
    }

    /**
     * A filled rhombus — the taxicab disc, which is exactly what a diamond is.
     *
     * <p>Stated as {@code |dx| + |dy| <= r} rather than as two triangles
     * meeting at the waist: thresholded down to 12, the triangles give four
     * straight rows of eight through the middle, a rounded blob rather than a
     * diamond. The taxicab form makes the rows step exactly one pixel apiece,
     * which is 45° on the nose and the only diagonal a pixel grid can draw
     * cleanly.
     */
    private record Rhombus(float cx, float cy, float rx, float ry) implements Shape {
        @Override
        public boolean holds(float x, float y) {
            return Math.abs(x - cx) / rx + Math.abs(y - cy) / ry <= 1f;
        }
    }

    private PipMask() {
    }

    private static Shape[] shapesFor(Suit suit) {
        return switch (suit) {
            case CLUBS -> new Shape[] {
                new Disc(32, 16, 13), new Disc(18, 36, 13), new Disc(46, 36, 13),
                new Tri(32, 40, 22, 62, 42, 62),
            };
            case DIAMONDS -> new Shape[] {new Rhombus(32, 32, 30, 30)};
            case HEARTS -> new Shape[] {
                new Disc(19, 20, 14), new Disc(45, 20, 14),
                new Tri(5, 26, 59, 26, 32, 60),
            };
            case SPADES -> new Shape[] {
                new Disc(18, 38, 14), new Disc(46, 38, 14),
                new Tri(32, 2, 4, 34, 60, 34), new Tri(32, 42, 22, 62, 42, 62),
            };
        };
    }

    /**
     * True where the pip is inked, row-major, {@link #SIZE} square.
     *
     * @param suit the suit to rasterise
     * @return a new array of {@code SIZE * SIZE} cells, top row first
     */
    static boolean[] generate(Suit suit) {
        Shape[] shapes = shapesFor(suit);
        boolean[] mask = new boolean[SIZE * SIZE];
        for (int y = 0; y < SIZE; y++) {
            for (int x = 0; x < SIZE; x++) {
                // The pixel's centre, in the 64-unit box the shapes are defined in.
                float sx = (x + 0.5f) * BOX / SIZE;
                float sy = (y + 0.5f) * BOX / SIZE;
                boolean on = false;
                for (Shape shape : shapes) {
                    on |= shape.holds(sx, sy);
                }
                mask[y * SIZE + x] = on;
            }
        }
        return mask;
    }
}
