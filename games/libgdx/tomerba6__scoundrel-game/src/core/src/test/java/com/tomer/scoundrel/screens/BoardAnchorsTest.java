package com.tomer.scoundrel.screens;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

/**
 * The board's anchors exist once.
 *
 * <p>{@link CardFlight} reads the rail's position from {@link BoardArt} rather
 * than keeping its own copy. Two copies drift apart without anything noticing,
 * and the equip flight then lands its card beside the well and snaps it into
 * place.
 *
 * <p>These assertions keep each anchor in one place.
 */
class BoardAnchorsTest {

    /** The equip flight lands on the centre of the rail icon. */
    @Test
    void equipFlightLandsOnTheRailIcon() {
        int iconCentreX = BoardArt.railIconX() + BoardArt.RAIL_ICON / 2;
        int iconCentreY = BoardArt.railIconY() + BoardArt.RAIL_ICON / 2;

        assertEquals(iconCentreX, CardFlight.EQUIP.toX(),
                "the equip flight must land where the rail icon is drawn");
        assertEquals(iconCentreY, CardFlight.EQUIP.toY(),
                "the equip flight must land where the rail icon is drawn");
    }

    /**
     * The lit block of the depth strip is kept on the board's centre, which is
     * where a swept room is aimed. Only the x is pinned: the sweep's y is tuned
     * against the strip's text line rather than its bar, and nothing here shows
     * that to be wrong.
     */
    @Test
    void avoidSweepAimsAtTheBoardCentre() {
        assertEquals(640, CardFlight.AVOID.toX(),
                "a swept room flies to the ticker, which sits on the board's centre");
    }
}
