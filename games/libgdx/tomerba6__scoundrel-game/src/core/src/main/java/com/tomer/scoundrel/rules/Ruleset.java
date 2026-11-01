package com.tomer.scoundrel.rules;

/**
 * Everything configurable about a game: constants plus the swappable
 * strategies. Variations and difficulty are different instances of this
 * record, not new engine code.
 *
 * @param startingHealth       health a new game starts on (20 in Standard, 14 in Frail)
 * @param healthCap            the most health a potion can heal up to (standard scoring
 *                             also reads it for the potion bonus)
 * @param roomSize             how many face-up cards a room is dealt up to (4)
 * @param cardsResolvedPerTurn how many of a room's cards must be resolved before the rest
 *                             carry over and the room refills (3)
 * @param potionsPerTurn       how many potions heal in one turn; any more are wasted (1)
 * @param avoidRule            when the current room may be avoided
 * @param scoring              how a finished game is scored
 * @param deck                 the cards the dungeon is built from, and their effects
 */
public record Ruleset(
        int startingHealth,
        int healthCap,
        int roomSize,
        int cardsResolvedPerTurn,
        int potionsPerTurn,
        AvoidRule avoidRule,
        ScoringStrategy scoring,
        DeckDefinition deck) {
}
