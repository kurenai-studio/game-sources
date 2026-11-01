package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.ToIntFunction;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * A row of buttons whose widths come from their labels, laid out centred with a
 * fixed gap — the run-end panel's four, measured at 112, 119, 106 and 122 wide
 * rather than one shared width.
 *
 * <p>The measuring needs a font, so it is passed in and the placing is
 * arithmetic. Same seam as {@link TextWrap}.
 */
class ButtonRowTest {

    /** A fake face: ten pixels a character plus fixed padding either side. */
    private static final ToIntFunction<String> TEN = s -> s.length() * 10 + 20;

    /** A single button takes its label's width and is centred in the region. */
    @Test
    void oneButtonIsCentredOnTheRow() {
        List<ButtonRow.Slot> slots = ButtonRow.lay(List.of("AB"), 0, 1000, 10, TEN);
        assertEquals(1, slots.size());
        assertEquals(40, slots.get(0).width());
        assertEquals(480, slots.get(0).x(), "centred on 1000");
    }

    /** Each button takes its own label's width. */
    @Test
    void widthsFollowTheLabelsRatherThanBeingShared() {
        List<ButtonRow.Slot> slots = ButtonRow.lay(List.of("A", "BBBB"), 0, 1000, 10, TEN);
        assertEquals(30, slots.get(0).width());
        assertEquals(60, slots.get(1).width());
    }

    /** Neighbouring buttons are exactly the gap apart. */
    @Test
    void theGapBetweenNeighboursIsExact() {
        List<ButtonRow.Slot> slots = ButtonRow.lay(List.of("AA", "BB", "CC"), 0, 1000, 10, TEN);
        for (int i = 1; i < slots.size(); i++) {
            ButtonRow.Slot previous = slots.get(i - 1);
            assertEquals(10, slots.get(i).x() - (previous.x() + previous.width()));
        }
    }

    /** The whole run, gaps included, sits centred — that is what "a row" means. */
    @Test
    void theWholeRunIsCentredNotJustTheFirstButton() {
        List<ButtonRow.Slot> slots = ButtonRow.lay(List.of("AA", "BBBB", "C"), 0, 1000, 10, TEN);
        ButtonRow.Slot first = slots.get(0);
        ButtonRow.Slot last = slots.get(slots.size() - 1);
        int left = first.x();
        int right = last.x() + last.width();
        assertEquals(1000 - right, left, "unequal margins either side");
    }

    /** Whole pixels only; a button on a half pixel is the blur the kit avoids. */
    @Test
    void everyEdgeLandsOnAWholePixel() {
        List<ButtonRow.Slot> slots = ButtonRow.lay(List.of("ODD", "LENGTHS", "HERE"), 0, 1001, 11, TEN);
        for (ButtonRow.Slot slot : slots) {
            assertEquals(slot.x(), Math.round((float) slot.x()));
            assertTrue(slot.width() > 0);
        }
    }

    /** No labels lay out as no slots. */
    @Test
    void anEmptyRowLaysNothingRatherThanThrowing() {
        assertEquals(List.of(), ButtonRow.lay(List.of(), 0, 1000, 10, TEN));
    }

    /**
     * The real row: the four labels at their measured widths land on their
     * measured x positions. Note it is centred on the <b>panel</b>, whose centre
     * is 638 — centring on the stage's 640 would put every button two pixels
     * right.
     */
    @Test
    void theRunEndRowMatchesTheReferenceRender() {
        ToIntFunction<String> measured = label -> switch (label) {
            case "NEW GAME" -> 112;
            case "MAIN MENU" -> 119;
            case "TROPHIES" -> 106;
            case "THE LEDGER" -> 122;
            default -> throw new AssertionError(label);
        };
        List<ButtonRow.Slot> slots = ButtonRow.lay(
                List.of("NEW GAME", "MAIN MENU", "TROPHIES", "THE LEDGER"),
                ScreenArt.END_X, ScreenArt.END_W, 10, measured);
        assertEquals(393, slots.get(0).x());
        assertEquals(515, slots.get(1).x());
        assertEquals(644, slots.get(2).x());
        assertEquals(760, slots.get(3).x());
    }

    // --- hit testing -------------------------------------------------------
    // GameScreen hit-tests the run-end buttons through indexAt, so a wrong
    // answer here leaves them dead.

    /** Three 100-wide buttons at x = 0, 110, 220, sitting on world-y 400..440. */
    private static List<ButtonRow.Slot> row() {
        return ButtonRow.lay(List.of("A", "B", "C"), 0, 330, 10, s -> 100);
    }

    /** A point on a button hits that button's index. */
    @Test
    void aPointInsideAButtonReturnsItsIndex() {
        assertEquals(0, ButtonRow.indexAt(row(), 400f, 40, 50f, 420f));
        assertEquals(1, ButtonRow.indexAt(row(), 400f, 40, 160f, 420f));
        assertEquals(2, ButtonRow.indexAt(row(), 400f, 40, 270f, 420f));
    }

    /** A point in the gap between buttons hits nothing. */
    @Test
    void aPointInTheGapBetweenButtonsHitsNothing() {
        assertEquals(PressGesture.NONE, ButtonRow.indexAt(row(), 400f, 40, 105f, 420f),
                "the 10px gap is not a target");
    }

    /** A point below the row, or on or above its top edge, hits nothing. */
    @Test
    void aPointAboveOrBelowTheRowHitsNothing() {
        assertEquals(PressGesture.NONE, ButtonRow.indexAt(row(), 400f, 40, 50f, 399f));
        assertEquals(PressGesture.NONE, ButtonRow.indexAt(row(), 400f, 40, 50f, 440f),
                "the top edge is exclusive");
    }

    /** A point on the row's bottom edge hits. */
    @Test
    void theBandIsInclusiveAtItsBottomEdge() {
        assertEquals(0, ButtonRow.indexAt(row(), 400f, 40, 50f, 400f));
    }

    /** An empty row hits nothing. */
    @Test
    void anEmptyRowHitsNothing() {
        assertEquals(PressGesture.NONE, ButtonRow.indexAt(List.of(), 400f, 40, 50f, 420f));
    }
}
