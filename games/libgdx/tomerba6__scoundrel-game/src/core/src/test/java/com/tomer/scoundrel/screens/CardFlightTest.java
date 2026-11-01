package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Cards leaving the room: swept to the depth ticker when a room is avoided, or
 * carried to the rail when a weapon is equipped. Both are the same motion — a
 * few whole-pixel hops with the card shrinking as it goes — so they share one
 * set of arithmetic and differ only in where they land and how many hops.
 */
class CardFlightTest {

    /** A sweep takes one position per hop, with nothing in between. */
    @Test
    void aFlightHopsRatherThanSliding() {
        // Each hop holds for its whole duration; there is no position between
        // one hop and the next, which is what makes it read as steps.
        Set<Integer> xs = new LinkedHashSet<>();
        for (float t = 0f; t < CardFlight.AVOID.total(); t += 0.005f) {
            xs.add(CardFlight.x(CardFlight.AVOID, 252, t));
        }
        assertEquals(CardFlight.AVOID.hops(), xs.size(),
                "expected one position per hop, got " + xs);
    }

    /** A sweep ends on the depth ticker's centre. */
    @Test
    void aFlightEndsOnItsAnchor() {
        float last = CardFlight.AVOID.total() - 0.001f;
        assertEquals(CardFlight.TICKER_CX, CardFlight.x(CardFlight.AVOID, 252, last));
        assertEquals(CardFlight.TICKER_CY, CardFlight.y(CardFlight.AVOID, 220, last));
    }

    /** A flight starts where the card was. */
    @Test
    void aFlightStartsWhereTheCardWas() {
        assertEquals(252, CardFlight.x(CardFlight.AVOID, 252, 0f));
        assertEquals(220, CardFlight.y(CardFlight.AVOID, 220, 0f));
    }

    /** Every position of the carry is a whole pixel, and none goes negative. */
    @Test
    void everyPositionIsAWholePixel() {
        // Ints throughout: there is no way to express a half-pixel here, which
        // is the point.
        for (float t = 0f; t < CardFlight.EQUIP.total(); t += 0.01f) {
            int x = CardFlight.x(CardFlight.EQUIP, 452, t);
            int y = CardFlight.y(CardFlight.EQUIP, 220, t);
            assertTrue(x >= 0 && y >= 0, "position went negative at t=" + t);
        }
    }

    /** The carry to the rail shrinks the card to 100%, 55% and 18% across its hops. */
    @Test
    void theEquipFlightShrinksThroughTheSpecifiedScales() {
        assertEquals(100, CardFlight.scale(CardFlight.EQUIP, 0f));
        assertEquals(55, CardFlight.scale(CardFlight.EQUIP, CardFlight.EQUIP.hopTime()));
        assertEquals(18, CardFlight.scale(CardFlight.EQUIP, 2 * CardFlight.EQUIP.hopTime()));
    }

    /** The sweep shrinks the card at every hop. */
    @Test
    void theAvoidSweepShrinksMonotonically() {
        int previous = 101;
        for (int hop = 0; hop < CardFlight.AVOID.hops(); hop++) {
            int scale = CardFlight.scale(CardFlight.AVOID, hop * CardFlight.AVOID.hopTime());
            assertTrue(scale < previous, "scale did not shrink at hop " + hop + ": " + scale);
            previous = scale;
        }
    }

    /**
     * A hop is a whole number of frames — one each, so a sweep and a carry each
     * take a quarter second; any longer is a long time to watch a card you have
     * finished with. A hop ending mid-frame would slide instead of stepping.
     *
     * <p>Asserted as "a whole number of frames" rather than with a modulo:
     * float remainder returns the divisor rather than zero when the division
     * lands a hair under an integer.
     */
    @Test
    void everyHopIsAWholeNumberOfFramesAndNoneOutstaysItsWelcome() {
        assertEquals(3, CardFlight.AVOID.hops());
        assertEquals(3, CardFlight.EQUIP.hops());
        float frame = 1f / 12f;
        for (CardFlight.Flight flight : new CardFlight.Flight[] {CardFlight.AVOID, CardFlight.EQUIP}) {
            float frames = flight.hopTime() / frame;
            assertEquals(Math.round(frames), frames, 1e-3f,
                    "hop is " + frames + " frames, which would end mid-frame");
        }
        // A hop a frame is the floor: anything faster is not on the grid.
        assertEquals(frame, CardFlight.AVOID.hopTime(), 1e-5f);
        assertEquals(frame, CardFlight.EQUIP.hopTime(), 1e-5f);
        assertTrue(CardFlight.EQUIP.total() <= 0.25f + 1e-5f,
                "the carry to the rail should be a quarter second, was "
                        + CardFlight.EQUIP.total());
    }

    /**
     * The whole room leaves together — one parallel action per card, no delay
     * between them. You scooped four cards; four cards go. Emptying them left to
     * right would read as four separate decisions rather than the one you
     * actually took, and cost a frame a card.
     */
    @Test
    void theWholeAvoidedRoomLeavesAtOnce() {
        assertEquals(0f, CardFlight.AVOID.staggerTime(), 1e-6f);
        for (int i = 0; i < 4; i++) {
            assertTrue(CardFlight.started(CardFlight.AVOID, i, 0f),
                    "card " + i + " should set off with the rest");
            assertTrue(CardFlight.landed(CardFlight.AVOID, i, CardFlight.AVOID.total()),
                    "card " + i + " should arrive with the rest");
        }
    }

    /** A full room's sweep takes a quarter second, as long as one card's. */
    @Test
    void aSweepTakesNoLongerForAFullRoomThanForOneCard() {
        assertEquals(CardFlight.AVOID.total(), CardFlight.AVOID.totalFor(4), 1e-5f);
        // Three hops of one frame: the shortest a three-hop flight can be at 12fps.
        assertEquals(0.25f, CardFlight.AVOID.totalFor(4), 1e-5f);
    }

    /** A flight is finished at its total time and not before. */
    @Test
    void aFlightFinishes() {
        assertFalse(CardFlight.AVOID.finished(CardFlight.AVOID.total() - 0.01f));
        assertTrue(CardFlight.AVOID.finished(CardFlight.AVOID.total()));
    }

    /**
     * A deal aims at the card's own slot, so unlike the sweep and the carry it
     * is built per card rather than being a constant. Every anchor in a flight
     * is a <b>centre</b> — the ticker and the rail
     * included, so a deal has to be built with the slot's centre and not its
     * left edge — aiming at the edge lands the card half a card too far left,
     * which on screen reads as the row being off rather than as a bug.
     */
    @Test
    void aDealLandsExactlyOnTheSlotCentreItWasBuiltFor() {
        int centre = CardArt.slotX(1) + CardArt.CARD_W / 2;
        int middle = CardArt.SLOT_Y + CardArt.CARD_H / 2;
        CardFlight.Flight deal = CardFlight.dealTo(centre, middle);
        float end = deal.total();
        assertEquals(centre, CardFlight.x(deal, CardFlight.TICKER_CX, end));
        assertEquals(middle, CardFlight.y(deal, CardFlight.TICKER_CY, end));
        assertEquals(100, CardFlight.scale(deal, end), "a dealt card ends full size");
    }

    /** A dealt card starts at the depth ticker, smaller than full size. */
    @Test
    void aDealStartsSmallAtTheDungeon() {
        CardFlight.Flight deal = CardFlight.dealTo(452, CardArt.SLOT_Y);
        assertEquals(CardFlight.TICKER_CX, CardFlight.x(deal, CardFlight.TICKER_CX, 0f));
        assertTrue(CardFlight.scale(deal, 0f) < 100, "it should grow as it comes");
    }

    /**
     * A card already on the board only moves; growing it would read as the
     * room being re-dealt rather than closing up.
     */
    @Test
    void aSlideNeverChangesSize() {
        CardFlight.Flight slide = CardFlight.slideTo(252, CardArt.SLOT_Y);
        for (float t = 0; t <= slide.total(); t += 1 / 60f) {
            assertEquals(100, CardFlight.scale(slide, t), "a slide resized at t=" + t);
        }
        assertEquals(252, CardFlight.x(slide, 452, slide.total()));
    }

    /**
     * One card's journey takes the same time either way, so a mixed room reads
     * as one movement rather than two overlapping ones. Only the stagger
     * differs — see {@link #aSlideMovesTheWholeRowAtOnceUnlikeADeal}.
     */
    @Test
    void aDealAndASlideRunToTheSameLength() {
        assertEquals(CardFlight.dealTo(0, 0).total(), CardFlight.slideTo(0, 0).total(), 1e-5f);
        assertEquals(CardFlight.dealTo(0, 0).hopTime(),
                CardFlight.slideTo(0, 0).hopTime(), 1e-5f);
    }

    /** Every hop of a deal is a whole number of frames. */
    @Test
    void everyDealHopIsAWholeFrame() {
        float frames = CardFlight.dealTo(0, 0).hopTime() / (1f / 12f);
        assertEquals(Math.round(frames), frames, 1e-3f);
    }

    /**
     * Whether a card has arrived. The depth ticker asks this of every card still
     * on its way up out of the dungeon: the engine gave the card up the instant
     * the move was applied, but on screen it is between the ticks and the table,
     * so its tick must stay lit until it lands.
     */
    @Test
    void aCardHasLandedOnlyOnceItsOwnFlightIsOver() {
        // On a staggered flight each card lands its own stagger later. The deal
        // is the only one that staggers; a sweep goes as one room.
        CardFlight.Flight deal = CardFlight.dealTo(452, CardArt.SLOT_Y);
        assertFalse(CardFlight.landed(deal, 0, 0f));
        assertTrue(CardFlight.landed(deal, 0, deal.total()));
        assertFalse(CardFlight.landed(deal, 2, deal.total()));
        assertTrue(CardFlight.landed(deal, 2, deal.total() + 2 * deal.staggerTime()));
    }

    /**
     * Every card of a four-card deal has landed exactly when the deal ends, and
     * the last not a moment before.
     */
    @Test
    void theWholeRoomIsDownExactlyWhenTheDealIsOver() {
        CardFlight.Flight deal = CardFlight.dealTo(452, CardArt.SLOT_Y);
        float end = deal.totalFor(4);
        for (int i = 0; i < 4; i++) {
            assertTrue(CardFlight.landed(deal, i, end), "card " + i + " should be down");
        }
        assertFalse(CardFlight.landed(deal, 3, end - 0.001f),
                "the last card is still in the air one tick before the end");
    }

    /**
     * The room lands one card at a time. A room that arrives all at once reads
     * as a single event rather than as four cards being dealt, so the stagger is
     * a whole frame: the smallest gap this grid can express, and enough to see
     * each card land.
     */
    @Test
    void aDealStaggersSoTheCardsLandOneAfterAnother() {
        CardFlight.Flight deal = CardFlight.dealTo(452, CardArt.SLOT_Y);
        assertEquals(1f / 12f, deal.staggerTime(), 1e-6f);
        // Each card is down a frame after the one to its left, and no two share
        // a landing — that is what makes the deal read as four separate cards.
        for (int i = 1; i < 4; i++) {
            float previousLanded = deal.total() + (i - 1) * deal.staggerTime();
            assertTrue(CardFlight.landed(deal, i - 1, previousLanded));
            assertFalse(CardFlight.landed(deal, i, previousLanded),
                    "card " + i + " landed with the one before it");
        }
        assertEquals(0.5f, deal.totalFor(4), 1e-5f);
    }

    /**
     * A slide does <b>not</b> stagger, and that is the difference between the
     * two. Cards arriving out of the dungeon are four separate events and read
     * better one after another; cards already on the table shifting up as the
     * room closes are one row adjusting, and staggering them would make a
     * resolved card look like it had triggered a second deal.
     */
    @Test
    void aSlideMovesTheWholeRowAtOnceUnlikeADeal() {
        CardFlight.Flight slide = CardFlight.slideTo(252, CardArt.SLOT_Y);
        assertEquals(0f, slide.staggerTime(), 1e-6f);
        assertEquals(slide.total(), slide.totalFor(4), 1e-6f,
                "every survivor should settle at the same moment");
        assertTrue(slide.staggerTime() < CardFlight.dealTo(0, 0).staggerTime(),
                "a slide must not inherit the deal's cascade");
    }
}
