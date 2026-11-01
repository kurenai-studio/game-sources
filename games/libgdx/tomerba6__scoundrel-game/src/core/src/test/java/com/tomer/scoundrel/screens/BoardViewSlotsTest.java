package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Where the cards of a room sit. A room shrinks as it is resolved, and the row
 * stays centred while it does — so this has to agree with the fixed four-slot
 * geometry the art was measured against, and keep agreeing at three, two and
 * one. The centring is the pure part of {@link BoardView}; the rest is drawing.
 */
class BoardViewSlotsTest {

    /** A full room sits on the four measured slots. */
    @Test
    void afullRoomLandsOnTheMeasuredFourSlots() {
        for (int i = 0; i < 4; i++) {
            assertEquals(CardArt.slotX(i), BoardView.slotX(i, 4),
                    "slot " + i + " of a full room should be the measured one");
        }
    }

    /** A room of one to four cards is centred. */
    @Test
    void aShorterRoomStaysCentred() {
        for (int cards = 1; cards <= 4; cards++) {
            int left = BoardView.slotX(0, cards);
            int right = (int) Theme.WORLD_WIDTH
                    - (BoardView.slotX(cards - 1, cards) + CardArt.CARD_W);
            assertEquals(left, right, "a room of " + cards + " should be centred");
        }
    }

    /** The gap between cards is 24px in any room. */
    @Test
    void theGapBetweenCardsNeverChanges() {
        for (int cards = 2; cards <= 4; cards++) {
            assertEquals(24, BoardView.slotX(1, cards) - (BoardView.slotX(0, cards) + CardArt.CARD_W),
                    "gap changed in a room of " + cards);
        }
    }

    /** One card sits dead centre, which is where a deal-in has to aim. */
    @Test
    void aSingleCardIsCentred() {
        assertEquals((int) (Theme.WORLD_WIDTH - CardArt.CARD_W) / 2, BoardView.slotX(0, 1));
    }
}
