package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.function.ToIntFunction;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Greedy word wrap. The measuring is passed in, because how wide a string is is
 * the one thing here that needs a font — everything else is arithmetic, and
 * arithmetic is what silently drops the last word off a trophy description.
 */
class TextWrapTest {

    /** A fake face: ten pixels a character, so line widths are countable by eye. */
    private static final ToIntFunction<String> TEN = s -> s.length() * 10;

    /** Text that fits stays on one line. */
    @Test
    void textThatFitsIsLeftAlone() {
        assertEquals(List.of("SHORT ENOUGH"), TextWrap.wrap("SHORT ENOUGH", 200, 2, TEN));
    }

    /** Given a budget the text actually fits in, no line is left over-wide. */
    @Test
    void itBreaksBetweenWordsNotInsideThem() {
        List<String> lines = TextWrap.wrap("CLEAR THE DUNGEON TEN TIMES", 120, 3, TEN);
        assertEquals(3, lines.size());
        for (String line : lines) {
            assertTrue(TEN.applyAsInt(line) <= 120, "line over the width: " + line);
            assertEquals(line.trim(), line, "a line kept its padding");
        }
        assertEquals("CLEAR THE DUNGEON TEN TIMES",
                String.join(" ", lines), "wrapping lost or moved a word");
    }

    /** A long text wraps with every word kept, in order. */
    @Test
    void everyWordSurvivesALongWrap() {
        String text = "FALL TO THE WORST SCORE THE DUNGEON CAN INFLICT — "
                + "MINUS ONE HUNDRED AND EIGHTY-EIGHT.";
        List<String> lines = TextWrap.wrap(text, 500, 2, TEN);
        assertEquals(2, lines.size());
        assertEquals(text, String.join(" ", lines));
    }

    /**
     * The row has space for a fixed number of lines. Anything past that is
     * folded back onto the last one rather than silently dropped — an
     * overhanging line is a bug you can see, a missing one is not.
     */
    @Test
    void textTooLongForTheRowKeepsItsTailOnTheLastLine() {
        List<String> lines = TextWrap.wrap("ONE TWO THREE FOUR FIVE SIX SEVEN", 40, 2, TEN);
        assertEquals(2, lines.size());
        assertEquals("ONE TWO THREE FOUR FIVE SIX SEVEN", String.join(" ", lines));
    }

    /** A single word wider than the line still gets its own line, uncut. */
    @Test
    void aWordWiderThanTheLineIsNotBroken() {
        List<String> lines = TextWrap.wrap("A SUPERCALIFRAGILISTIC B", 60, 3, TEN);
        assertTrue(lines.contains("SUPERCALIFRAGILISTIC"));
        assertEquals("A SUPERCALIFRAGILISTIC B", String.join(" ", lines));
    }

    /** Empty text gives one empty line. */
    @Test
    void emptyTextIsOneEmptyLineRatherThanNothing() {
        assertEquals(List.of(""), TextWrap.wrap("", 100, 2, TEN));
    }

    /** One line asked for means one line back, however long the text is. */
    @Test
    void aSingleLineBudgetNeverWraps() {
        List<String> lines = TextWrap.wrap("ONE TWO THREE FOUR FIVE", 40, 1, TEN);
        assertEquals(List.of("ONE TWO THREE FOUR FIVE"), lines);
    }
}
