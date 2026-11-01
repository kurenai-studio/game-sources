package com.tomer.scoundrel.rules;

import java.util.List;
import java.util.Optional;

/**
 * The shipped difficulty modes, in menu order. Standard leads and is the only
 * mode whose runs count toward achievements; the variants still record runs and
 * per-mode high scores. Adding a mode is a new entry here — nothing else changes.
 */
public final class GameModes {

    private GameModes() {
    }

    /** Base Scoundrel: first in the menu, the tutorial's rules, and the only mode achievements count in. */
    public static final GameMode STANDARD = new GameMode(
            "standard", "Standard",
            "The classic dungeon. Scoop a room to skip it now and then — but never twice in a row.",
            Rulesets.standard(), true);

    private static final List<GameMode> CATALOG = List.of(
            STANDARD,
            new GameMode("relentless", "Relentless",
                    "No escape: you may never avoid a room. Face every card the dungeon deals.",
                    Rulesets.relentless(), false),
            new GameMode("frail", "Frail",
                    "You begin at 14 health and can never heal past it. Every wound bites deeper.",
                    Rulesets.frail(), false));

    /**
     * Every shipped mode, in menu order.
     *
     * @return an unmodifiable list, {@link #STANDARD} first
     */
    public static List<GameMode> all() {
        return CATALOG;
    }

    /**
     * The mode with this id, or empty for an unknown or retired id (e.g. an old log).
     *
     * @param id a {@link GameMode#id()}, typically read back from a run record
     * @return the matching mode, or empty
     */
    public static Optional<GameMode> byId(String id) {
        return CATALOG.stream().filter(mode -> mode.id().equals(id)).findFirst();
    }
}
