package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Where the tutorial's callout goes, and where its notch points.
 *
 * <p>Everything is design space with y measured downward, as the art is
 * specified. The callout prefers to sit above the card it is talking about and
 * drops below when there is no room; the notch always points back at the card,
 * so the two must agree — a callout below the card with a notch still pointing
 * down is the one bug this can have and it is invisible in a still.
 */
class CalloutPlacementTest {

    private static final int W = 422;
    private static final int H = 122;
    private static final int GAP = 13;
    private static final int WORLD = 1280;

    private static CalloutPlacement.Placement place(int targetX, int targetY, int targetW, int targetH) {
        return CalloutPlacement.place(targetX, targetY, targetW, targetH, W, H, GAP, WORLD);
    }

    /** The room row sits low enough that the callout always fits above it. */
    @Test
    void itSitsAboveTheCardWhenThereIsRoom() {
        CalloutPlacement.Placement p = place(250, 232, 176, 256);
        assertFalse(p.below());
        assertEquals(232 - GAP - H, p.y());
        assertTrue(p.y() >= 0);
    }

    /** With no room above the card, the callout sits below it, one gap clear. */
    @Test
    void itDropsBelowWhenThereIsNotRoomAbove() {
        CalloutPlacement.Placement p = place(250, 40, 176, 256);
        assertTrue(p.below());
        assertEquals(40 + 256 + GAP, p.y());
    }

    /** The callout is centred on its card. */
    @Test
    void itIsCentredOnTheTarget() {
        CalloutPlacement.Placement p = place(640 - 88, 232, 176, 256);
        assertEquals(640 - W / 2, p.x());
    }

    /** A card at the edge of the row must not push the callout off the stage. */
    @Test
    void itIsClampedInsideTheStage() {
        CalloutPlacement.Placement left = place(40, 232, 176, 256);
        assertTrue(left.x() >= CalloutPlacement.MARGIN);
        CalloutPlacement.Placement right = place(1040, 232, 176, 256);
        assertTrue(right.x() + W <= WORLD - CalloutPlacement.MARGIN);
    }

    /** The notch points at the card's middle — that is the only thing it is for. */
    @Test
    void theNotchPointsAtTheCentreOfTheTarget() {
        CalloutPlacement.Placement p = place(640 - 88, 232, 176, 256);
        assertEquals(640 - CalloutPlacement.NOTCH_W / 2, p.notchX());
    }

    /**
     * When the callout has been clamped, the notch has to stay on the panel or
     * it detaches and points at nothing.
     */
    @Test
    void theNotchStaysOnThePanelEvenWhenTheCalloutIsClamped() {
        for (int targetX : new int[] {0, 40, 400, 1040, 1200}) {
            CalloutPlacement.Placement p = place(targetX, 232, 176, 256);
            assertTrue(p.notchX() >= p.x() + CalloutPlacement.MARGIN,
                    "notch ran off the left of the panel at target " + targetX);
            assertTrue(p.notchX() + CalloutPlacement.NOTCH_W <= p.x() + W - CalloutPlacement.MARGIN,
                    "notch ran off the right of the panel at target " + targetX);
        }
    }

    /**
     * An explanation beat points at nothing, so it gets no notch — and it goes
     * under the room, not over it. Dead-centre covers the cards the player is
     * being told about; above the row pushes a five-line panel into the HUD.
     */
    @Test
    void anExplanationBeatSitsUnderTheRoomAndHasNoNotch() {
        CalloutPlacement.Placement p = CalloutPlacement.belowRow(232, 256, W, H, GAP, WORLD, 720);
        assertEquals((WORLD - W) / 2, p.x(), "centred across the stage");
        assertEquals(232 + 256 + GAP, p.y(), "clear of the room row");
        assertFalse(p.hasNotch());
        assertFalse(p.below());
    }

    /** The tallest narration still has to land on the stage. */
    @Test
    void anExplanationBeatIsClampedInsideTheStage() {
        CalloutPlacement.Placement tall = CalloutPlacement.belowRow(232, 256, W, 300, GAP, WORLD, 720);
        assertTrue(tall.y() >= CalloutPlacement.MARGIN);
        assertTrue(tall.y() + 300 <= 720, "the callout runs off the bottom");
    }

    /** A callout placed on a card has a notch, above it or below. */
    @Test
    void aPlacedCalloutAlwaysHasItsNotch() {
        assertTrue(place(250, 232, 176, 256).hasNotch());
        assertTrue(place(250, 40, 176, 256).hasNotch());
    }

    // --- the NEXT plate ----------------------------------------------------

    /** The NEXT plate's right edge sits one pad in from the callout's right edge. */
    @Test
    void theNextPlateIsRightAlignedInsideTheCallout() {
        CalloutPlacement.Plate plate = CalloutPlacement.nextPlate(100, 200, 180, 40);

        assertEquals(100 + ScreenArt.CALLOUT_W - ScreenArt.CALLOUT_PAD_X,
                plate.x() + plate.w(),
                "its right edge sits one pad in from the callout's right edge");
    }

    /**
     * The NEXT plate is the skip plate's height and sits one bottom pad up from
     * the callout's bottom edge.
     */
    @Test
    void theNextPlateSitsBelowTheLastLineRatherThanOverIt() {
        int calloutY = 200;
        int calloutH = 180;
        CalloutPlacement.Plate plate = CalloutPlacement.nextPlate(100, calloutY, calloutH, 40);

        assertEquals(calloutY + calloutH - ScreenArt.CALLOUT_BOTTOM_PAD - ScreenArt.SKIP_H,
                plate.y());
        assertEquals(ScreenArt.SKIP_H, plate.h());
    }

    /** The NEXT plate is its label's width plus padding each side, so a longer label widens it. */
    @Test
    void theNextPlateWidensWithItsLabel() {
        int narrow = CalloutPlacement.nextPlate(100, 200, 180, 40).w();
        int wide = CalloutPlacement.nextPlate(100, 200, 180, 90).w();

        assertEquals(40 + 2 * ScreenArt.END_BUTTON_PAD_X, narrow, "padding on both sides");
        assertTrue(wide > narrow);
    }

    /** A taller callout moves its NEXT plate down with its bottom edge. */
    @Test
    void aTallerCalloutPushesItsNextPlateDown() {
        int shortOne = CalloutPlacement.nextPlate(100, 200, 150, 40).y();
        int tallOne = CalloutPlacement.nextPlate(100, 200, 220, 40).y();

        assertTrue(tallOne > shortOne, "the plate follows the callout's bottom");
    }
}
