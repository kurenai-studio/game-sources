package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The eight ticks that ring the card the tutorial is talking about.
 *
 * <p>The ticks are eight 24×4 marks that leave the edges <em>open</em> —
 * corners only, never a closed box. That last part is the whole reason it is
 * ticks and not a frame: a closed outline reads as a second card border and
 * fights the one already printed on the card.
 */
class CornerTicksTest {

    private static final int X = 250;
    private static final int Y = 232;
    private static final int W = 176;
    private static final int H = 256;

    private static List<CornerTicks.Tick> ticks() {
        return CornerTicks.around(X, Y, W, H);
    }

    /** There are eight ticks. */
    @Test
    void thereAreEightOfThemTwoPerCorner() {
        assertEquals(8, ticks().size());
    }

    /** Every tick is 24×4, lying either way. */
    @Test
    void everyTickIsTwentyFourByFour() {
        for (CornerTicks.Tick tick : ticks()) {
            boolean horizontal = tick.w() == CornerTicks.LENGTH && tick.h() == CornerTicks.THICK;
            boolean vertical = tick.w() == CornerTicks.THICK && tick.h() == CornerTicks.LENGTH;
            assertTrue(horizontal || vertical,
                    "tick is " + tick.w() + "x" + tick.h() + ", not 24x4 either way round");
        }
        assertEquals(24, CornerTicks.LENGTH);
        assertEquals(4, CornerTicks.THICK);
    }

    /**
     * The middle of every edge stays clear. This is the property that makes them
     * ticks; without it the same eight rects could be a box.
     */
    @Test
    void theMiddleOfEachEdgeIsLeftOpen() {
        int midX = X + W / 2;
        int midY = Y + H / 2;
        for (CornerTicks.Tick tick : ticks()) {
            assertFalse(covers(tick, midX, Y) || covers(tick, midX, Y + H),
                    "a tick reaches the middle of a horizontal edge");
            assertFalse(covers(tick, X, midY) || covers(tick, X + W, midY),
                    "a tick reaches the middle of a vertical edge");
        }
    }

    /** Each corner gets exactly two, and they meet there rather than floating. */
    @Test
    void eachCornerHasOneArmEachWayMeetingAtTheCorner() {
        int[][] corners = {{X, Y}, {X + W, Y}, {X, Y + H}, {X + W, Y + H}};
        for (int[] corner : corners) {
            long near = ticks().stream()
                    .filter(t -> Math.abs(t.x() - corner[0]) <= CornerTicks.LENGTH
                            && Math.abs(t.y() - corner[1]) <= CornerTicks.LENGTH)
                    .count();
            assertEquals(2, near, "corner " + corner[0] + "," + corner[1] + " has " + near + " arms");
        }
    }

    /** They ring the card from outside, so none of them covers its art. */
    @Test
    void noTickSitsOverTheCardItIsPointingAt() {
        for (CornerTicks.Tick tick : ticks()) {
            boolean insideH = tick.x() >= X && tick.x() + tick.w() <= X + W;
            boolean insideV = tick.y() >= Y && tick.y() + tick.h() <= Y + H;
            assertFalse(insideH && insideV, "a tick is wholly inside the card");
        }
    }

    /** Whole pixels; these are hand-placed marks on a pixel grid. */
    @Test
    void everyEdgeIsAWholePixel() {
        for (CornerTicks.Tick tick : ticks()) {
            assertEquals(tick.x(), (int) tick.x());
            assertEquals(tick.y(), (int) tick.y());
        }
    }

    private static boolean covers(CornerTicks.Tick tick, int px, int py) {
        return px >= tick.x() && px < tick.x() + tick.w()
                && py >= tick.y() && py < tick.y() + tick.h();
    }
}
