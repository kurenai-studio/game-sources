package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.screens.CardHitRegions.CardRect;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.screens.CardHitRegions.cardAt;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/** Geometry behind skip-and-act: which card did the skipping click land on? */
class CardHitRegionsTest {

    private static final Card LEFT = new Card("QS", CardType.MONSTER, 12);
    private static final Card RIGHT = new Card("5D", CardType.WEAPON, 5);

    /** Two 170x240 tiles, bottom edge y=240, with a 24px gap (270..294). */
    private static final List<CardRect> ROW = List.of(
            new CardRect(LEFT, 100, 240, 170, 240),
            new CardRect(RIGHT, 294, 240, 170, 240));

    /** A point inside a card returns that card. */
    @Test
    void aPointInsideACardReturnsThatCard() {
        assertEquals(LEFT, cardAt(ROW, 185, 360));
        assertEquals(RIGHT, cardAt(ROW, 379, 360));
    }

    /** A point in the gap between cards hits nothing. */
    @Test
    void aPointInTheGapBetweenCardsHitsNothing() {
        assertNull(cardAt(ROW, 282, 360));
    }

    /** A point above or below the row hits nothing. */
    @Test
    void aPointAboveOrBelowTheRowHitsNothing() {
        assertNull(cardAt(ROW, 185, 100));
        assertNull(cardAt(ROW, 185, 600));
    }

    /** A point left or right of every card hits nothing. */
    @Test
    void aPointLeftOrRightOfEveryCardHitsNothing() {
        assertNull(cardAt(ROW, 40, 360));
        assertNull(cardAt(ROW, 1200, 360));
    }

    /** A point on a card's edge or corner hits it. */
    @Test
    void cardEdgesAreInclusive() {
        assertEquals(LEFT, cardAt(ROW, 100, 240));  // bottom-left corner
        assertEquals(LEFT, cardAt(ROW, 270, 480));  // top-right corner
    }

    /** With no cards, nothing is hit. */
    @Test
    void withNoCardsOnScreenNothingIsHit() {
        assertNull(cardAt(List.of(), 185, 360));
    }

    /** Where cards overlap, the one drawn last wins. */
    @Test
    void whenRectsOverlapTheTopmostWins() {
        List<CardRect> stacked = List.of(
                new CardRect(LEFT, 0, 0, 100, 100),
                new CardRect(RIGHT, 50, 50, 100, 100));
        assertEquals(RIGHT, cardAt(stacked, 75, 75));
        assertEquals(LEFT, cardAt(stacked, 25, 25));
    }
}
