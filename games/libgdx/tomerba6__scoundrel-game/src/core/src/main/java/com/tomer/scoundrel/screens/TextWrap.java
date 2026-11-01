package com.tomer.scoundrel.screens;

import java.util.ArrayList;
import java.util.List;
import java.util.function.ToIntFunction;

/**
 * Greedy word wrap into a fixed number of lines.
 *
 * <p>How wide a string is is the one part of this that needs a font, so it is
 * passed in and the rest is arithmetic — which is what silently drops the last
 * word off a description and is exactly what a test can catch.
 *
 * <p>Text that will not fit in the line budget keeps its tail on the last line
 * rather than being cut. An overhanging line is a bug anyone can see in a
 * screenshot; a missing one reads as copy that was always that short.
 */
final class TextWrap {

    private TextWrap() {
    }

    /**
     * Wraps {@code text} at its spaces, filling each line greedily.
     *
     * @param text     the words to wrap, separated by single spaces
     * @param maxWidth how wide a line may be, in the same units {@code measure} returns
     * @param maxLines how many lines the row has room for; the last one takes any overflow
     * @param measure  a line's width, usually the font's measured width in pixels
     * @return between 1 and {@code maxLines} lines, every word kept
     */
    static List<String> wrap(String text, int maxWidth, int maxLines, ToIntFunction<String> measure) {
        String[] words = text.split(" ");
        List<String> lines = new ArrayList<>();
        StringBuilder line = new StringBuilder();
        for (String word : words) {
            if (line.isEmpty()) {
                line.append(word);
                continue;
            }
            // Once the budget is down to its last line, everything left joins it.
            if (lines.size() + 1 >= maxLines) {
                line.append(' ').append(word);
                continue;
            }
            String candidate = line + " " + word;
            if (measure.applyAsInt(candidate) <= maxWidth) {
                line.setLength(0);
                line.append(candidate);
            } else {
                lines.add(line.toString());
                line.setLength(0);
                line.append(word);
            }
        }
        lines.add(line.toString());
        return List.copyOf(lines);
    }
}
