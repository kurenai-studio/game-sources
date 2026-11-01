package com.tomer.scoundrel.screens;

import java.util.ArrayList;
import java.util.List;

/**
 * The event feed down the right margin: a few lines that hold, fade and go.
 *
 * <p>Pure state with no widgets, so it can be tested headlessly and so the fade
 * is something decided rather than something a toolkit happens to do. The fade
 * runs in whole steps: a continuous one puts the text on a slightly different
 * colour every frame, which at this resolution reads as the letters crawling.
 */
final class Feed {

    /** As many as the margin holds beside the room. */
    static final int MAX_LINES = 4;
    /** How long a line reads at full strength before it starts to go. */
    static final float HOLD = 4f;
    /** How long a line takes to fade out once its hold is over, in seconds. */
    static final float FADE = 1.5f;
    /** The fade's whole steps — the only alphas a line is ever drawn at. */
    static final int FADE_STEPS = 5;

    private static final class Line {
        final String text;
        float age;

        Line(String text) {
            this.text = text;
        }
    }

    private final List<Line> lines = new ArrayList<>();

    /** Creates an empty feed. */
    Feed() {
    }

    /**
     * Adds a line at the bottom, dropping the oldest past {@link #MAX_LINES}.
     *
     * @param text the line, as {@link FeedText} words it
     */
    void push(String text) {
        lines.add(new Line(text));
        while (lines.size() > MAX_LINES) {
            lines.remove(0);
        }
    }

    /**
     * Ages every line, and drops any that has finished fading.
     *
     * @param delta seconds since the last frame
     */
    void update(float delta) {
        for (Line line : lines) {
            line.age += delta;
        }
        lines.removeIf(line -> line.age >= HOLD + FADE);
    }

    /** Drops every line at once, for a new run. */
    void clear() {
        lines.clear();
    }

    /**
     * How many lines are showing.
     *
     * @return 0 to {@link #MAX_LINES}
     */
    int size() {
        return lines.size();
    }

    /**
     * A line's text.
     *
     * @param index from 0 (the oldest) to {@code size() - 1} (the newest)
     * @return the text as pushed
     */
    String textAt(int index) {
        return lines.get(index).text;
    }

    /**
     * How strongly a line is drawn: full while it holds, then down by steps.
     *
     * @param index from 0 (the oldest) to {@code size() - 1} (the newest)
     * @return 1 while holding, then 0.8, 0.6, 0.4, 0.2 and 0 as it fades
     */
    float alphaAt(int index) {
        float age = lines.get(index).age;
        if (age <= HOLD) {
            return 1f;
        }
        float gone = (age - HOLD) / FADE;
        int step = Math.min(FADE_STEPS, (int) Math.ceil(gone * FADE_STEPS));
        return Math.max(0f, (FADE_STEPS - step) / (float) FADE_STEPS);
    }
}
