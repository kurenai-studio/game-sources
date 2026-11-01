package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The fading event feed, as state rather than as animated widgets. Its fade is
 * stepped: a smooth one puts the text on a different colour every frame, and at
 * this resolution that is the same shimmer everything else here exists to
 * avoid.
 */
class FeedTest {

    /** A new line is at full strength. */
    @Test
    void aNewLineIsAtFullStrength() {
        Feed feed = new Feed();
        feed.push("the ogre falls");
        assertEquals(1, feed.size());
        assertEquals("the ogre falls", feed.textAt(0));
        assertEquals(1f, feed.alphaAt(0), 1e-4);
    }

    /** Lines stack oldest first, newest last. */
    @Test
    void linesStackNewestLast() {
        Feed feed = new Feed();
        feed.push("first");
        feed.push("second");
        assertEquals("first", feed.textAt(0));
        assertEquals("second", feed.textAt(1));
    }

    /** Four lines is what the margin holds; the oldest drops off. */
    @Test
    void theFeedNeverGrowsPastItsMargin() {
        Feed feed = new Feed();
        for (int i = 0; i < 10; i++) {
            feed.push("line " + i);
        }
        assertEquals(Feed.MAX_LINES, feed.size());
        assertEquals("line 9", feed.textAt(Feed.MAX_LINES - 1));
        assertEquals("line 6", feed.textAt(0));
    }

    /** A line stays at full strength until its hold is over. */
    @Test
    void aLineHoldsAtFullStrengthBeforeItStartsToGo() {
        Feed feed = new Feed();
        feed.push("held");
        feed.update(Feed.HOLD - 0.01f);
        assertEquals(1f, feed.alphaAt(0), 1e-4);
    }

    /**
     * The fade is a fixed number of steps, and each holds — every alpha the
     * feed ever draws with is one of them.
     */
    @Test
    void theFadeOnlyEverUsesItsOwnSteps() {
        Feed feed = new Feed();
        feed.push("going");
        for (float t = 0; t < Feed.HOLD + Feed.FADE + 0.5f; t += 1 / 60f) {
            if (feed.size() == 0) {
                break;
            }
            float alpha = feed.alphaAt(0);
            float steps = alpha * Feed.FADE_STEPS;
            assertEquals(Math.round(steps), steps, 1e-4,
                    "alpha " + alpha + " is not on a step at t=" + t);
            feed.update(1 / 60f);
        }
    }

    /** A line is removed once it has faded. */
    @Test
    void aLineGoesOutAltogetherOnceItHasFaded() {
        Feed feed = new Feed();
        feed.push("gone");
        feed.update(Feed.HOLD + Feed.FADE + 0.01f);
        assertEquals(0, feed.size());
    }

    /** Lines age independently, so a new one does not revive an old one. */
    @Test
    void anOlderLineIsFainterThanANewerOne() {
        Feed feed = new Feed();
        feed.push("old");
        feed.update(Feed.HOLD + Feed.FADE / 2f);
        feed.push("new");
        assertTrue(feed.alphaAt(0) < feed.alphaAt(1),
                "the older line should be the fainter one");
    }

    /** Clearing removes every line. */
    @Test
    void clearingEmptiesIt() {
        Feed feed = new Feed();
        feed.push("a");
        feed.clear();
        assertEquals(0, feed.size());
    }
}
