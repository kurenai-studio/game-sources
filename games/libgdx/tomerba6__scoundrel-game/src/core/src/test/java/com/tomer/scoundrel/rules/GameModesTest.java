package com.tomer.scoundrel.rules;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The catalog of game modes the menu offers. */
class GameModesTest {

    /** The three modes each have a unique id, a title, a description and a ruleset, with Standard first. */
    @Test
    void catalogHasUniqueIdsAndCopyWithStandardFirst() {
        List<GameMode> all = GameModes.all();
        assertEquals(3, all.size());
        assertEquals("standard", all.get(0).id(), "Standard leads the menu");
        Set<String> ids = new HashSet<>();
        for (GameMode m : all) {
            assertTrue(ids.add(m.id()), "duplicate id " + m.id());
            assertFalse(m.title().isBlank(), m.id() + " has a blank title");
            assertFalse(m.description().isBlank(), m.id() + " has a blank description");
            assertNotNull(m.ruleset(), m.id() + " has no ruleset");
        }
    }

    /** Only Standard counts towards achievements. */
    @Test
    void onlyStandardTracksAchievements() {
        for (GameMode m : GameModes.all()) {
            assertEquals(m.id().equals("standard"), m.tracksAchievements(), m.id());
        }
    }

    /** Relentless never allows avoiding, Frail starts at 14 and Standard at 20. */
    @Test
    void eachModeCarriesItsMatchingRuleset() {
        assertTrue(GameModes.byId("relentless").orElseThrow().ruleset().avoidRule()
                instanceof NeverAvoidRule);
        assertEquals(14, GameModes.byId("frail").orElseThrow().ruleset().startingHealth());
        assertEquals(20, GameModes.STANDARD.ruleset().startingHealth());
    }

    /** Looking up a known id finds its mode; an unknown or empty id finds nothing. */
    @Test
    void byIdFindsAKnownModeAndIsEmptyForAnUnknownOne() {
        assertEquals("Relentless", GameModes.byId("relentless").orElseThrow().title());
        assertEquals(Optional.empty(), GameModes.byId("no-such-mode"));
        assertEquals(Optional.empty(), GameModes.byId(""));
    }
}
