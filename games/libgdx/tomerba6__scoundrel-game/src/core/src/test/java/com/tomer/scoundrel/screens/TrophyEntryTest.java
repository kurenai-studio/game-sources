package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.achievements.Achievement;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** One entry in TROPHIES: what a row says, and whether its seal is filled. */
class TrophyEntryTest {

    private static Achievement open() {
        return new Achievement("first_blood", "First Blood",
                "Clear the dungeon for the first time.", false, context -> true);
    }

    private static Achievement secret() {
        return new Achievement("rock_bottom", "Rock Bottom",
                "Fall to the worst score the dungeon can inflict.", true, context -> true);
    }

    private static Instant july27() {
        return ZonedDateTime.of(2026, 7, 27, 9, 30, 0, 0, ZoneId.systemDefault()).toInstant();
    }

    /** An earned trophy is lit and reads EARNED with the day it was won. */
    @Test
    void anEarnedTrophyIsLitAndCarriesTheDayItWasWon() {
        TrophyEntry entry = TrophyEntry.of(open(), july27());
        assertTrue(entry.earned());
        assertEquals("FIRST BLOOD", entry.title());
        assertEquals("CLEAR THE DUNGEON FOR THE FIRST TIME.", entry.description());
        assertEquals("EARNED JUL 27", entry.status());
    }

    /** A locked trophy still shows its name and rule, and reads LOCKED. */
    @Test
    void aLockedTrophyStillSaysWhatToAimFor() {
        TrophyEntry entry = TrophyEntry.of(open(), null);
        assertFalse(entry.earned());
        assertEquals("FIRST BLOOD", entry.title());
        assertEquals("CLEAR THE DUNGEON FOR THE FIRST TIME.", entry.description());
        assertEquals("LOCKED", entry.status());
    }

    /** A hidden one gives nothing away until it is won — that is the whole point. */
    @Test
    void aHiddenTrophyKeepsItsNameAndItsRuleUntilItIsEarned() {
        TrophyEntry hidden = TrophyEntry.of(secret(), null);
        assertEquals("???", hidden.title());
        assertFalse(hidden.description().contains("WORST"), "the rule leaked through");
        assertFalse(hidden.earned());
    }

    /** A hidden trophy shows its name and rule once earned. */
    @Test
    void aHiddenTrophyRevealsItselfOnceEarned() {
        TrophyEntry revealed = TrophyEntry.of(secret(), july27());
        assertEquals("ROCK BOTTOM", revealed.title());
        assertTrue(revealed.description().contains("WORST"));
        assertEquals("EARNED JUL 27", revealed.status());
    }

    /**
     * The empty well is the locked state — there is no padlock glyph and no
     * greyscale filter, so the seal's fill is the only thing that says it.
     */
    @Test
    void theSealsFillIsTheOnlyDifferenceBetweenEarnedAndLocked() {
        assertEquals(ScreenArt.SEAL_EARNED, TrophyEntry.of(open(), july27()).sealColour());
        assertEquals(ScreenArt.SEAL_LOCKED, TrophyEntry.of(open(), null).sealColour());
        assertNotEquals(ScreenArt.ROW_EARNED, ScreenArt.ROW_LOCKED);
        assertEquals(ScreenArt.ROW_EARNED, TrophyEntry.of(open(), july27()).rowColour());
        assertEquals(ScreenArt.ROW_LOCKED, TrophyEntry.of(open(), null).rowColour());
    }
}
