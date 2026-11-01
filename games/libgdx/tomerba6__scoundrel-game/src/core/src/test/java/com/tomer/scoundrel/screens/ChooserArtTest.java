package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The move chooser's geometry: a stack of gold plates over the card that opened
 * it. It is the only popup on the board and it sits on the hot path — every
 * armed monster goes through it — so where it is drawn and where it is hit have
 * to be the same numbers, computed once, here.
 */
class ChooserArtTest {

    /** Nothing on this board is a different button; the plate is Avoid's. */
    @Test
    void aChoiceIsTheSamePlateTheAvoidButtonIs() {
        assertEquals(HudArt.AVOID_H, ChooserArt.PLATE_H);
    }

    /** A stack of two or three plates is centred on the card's middle, to within a pixel. */
    @Test
    void theStackIsCentredOnTheCardThatOpenedIt() {
        for (int count = 2; count <= 3; count++) {
            int top = ChooserArt.plateY(0, count);
            int bottom = ChooserArt.plateY(count - 1, count) + ChooserArt.PLATE_H;
            assertEquals(CardArt.SLOT_Y + CardArt.CARD_H / 2, (top + bottom) / 2, 1,
                    "a stack of " + count + " should straddle the card's middle");
        }
    }

    /** Plates stack one gap apart, without overlapping. */
    @Test
    void thePlatesStackWithoutOverlapping() {
        int first = ChooserArt.plateY(0, 2);
        int second = ChooserArt.plateY(1, 2);
        assertTrue(second >= first + ChooserArt.PLATE_H, "plates overlap");
        assertEquals(ChooserArt.PLATE_H + ChooserArt.GAP, second - first);
    }

    /** A plate is centred on the card and must not spill out past its frame. */
    @Test
    void aPlateSitsInsideTheCardItBelongsTo() {
        int slot = CardArt.slotX(1);
        int width = ChooserArt.plateW(80); // a label about as wide as "USE WEAPON"
        int x = ChooserArt.plateX(slot, width);
        assertTrue(width <= CardArt.CARD_W, "the plate is wider than the card");
        assertEquals(slot + (CardArt.CARD_W - width) / 2, x);
        assertTrue(x >= slot && x + width <= slot + CardArt.CARD_W);
    }

    /**
     * Hit where drawn. The pointer arrives with y upward and the plates are
     * specified with y downward, exactly as the Avoid button is — get the flip
     * wrong and the chooser works somewhere else entirely.
     */
    @Test
    void eachPlateIsHitWhereItIsDrawn() {
        int slot = CardArt.slotX(0);
        int width = ChooserArt.plateW(80);
        for (int i = 0; i < 2; i++) {
            float middleY = CardArt.toWorldY(ChooserArt.plateY(i, 2), ChooserArt.PLATE_H)
                    + ChooserArt.PLATE_H / 2f;
            float middleX = ChooserArt.plateX(slot, width) + width / 2f;
            assertEquals(i, ChooserArt.indexAt(slot, width, 2, middleX, middleY),
                    "plate " + i + " should be hit at its own middle");
        }
    }

    /** A press in the gap between plates hits nothing. */
    @Test
    void theGapBetweenPlatesHitsNothing() {
        int slot = CardArt.slotX(0);
        int width = ChooserArt.plateW(80);
        // One pixel into the gap, measured down from the first plate's foot.
        int gapTop = ChooserArt.plateY(0, 2) + ChooserArt.PLATE_H;
        float y = CardArt.toWorldY(gapTop + 1, 0);
        float x = ChooserArt.plateX(slot, width) + width / 2f;
        assertEquals(-1, ChooserArt.indexAt(slot, width, 2, x, y));
    }

    /** A press just left or right of the stack hits nothing. */
    @Test
    void aPressBesideTheStackHitsNothing() {
        int slot = CardArt.slotX(0);
        int width = ChooserArt.plateW(80);
        float y = CardArt.toWorldY(ChooserArt.plateY(0, 2), ChooserArt.PLATE_H)
                + ChooserArt.PLATE_H / 2f;
        int left = ChooserArt.plateX(slot, width);
        assertEquals(-1, ChooserArt.indexAt(slot, width, 2, left - 1, y));
        assertEquals(-1, ChooserArt.indexAt(slot, width, 2, left + width, y));
    }

    /** Mirroring the y is not the same as not mirroring it — pin that it is not. */
    @Test
    void theStackIsNotHitAtItsDesignSpaceY() {
        int slot = CardArt.slotX(0);
        int width = ChooserArt.plateW(80);
        float x = ChooserArt.plateX(slot, width) + width / 2f;
        assertFalse(ChooserArt.indexAt(slot, width, 2, x, ChooserArt.plateY(0, 2) + 4) >= 0,
                "design-space y should not hit");
    }
}
