package com.tomer.scoundrel.model;

import java.util.List;

/**
 * Immutable snapshot of a whole game. Index 0 of {@code dungeon} is the top
 * of the face-down pile. {@code weapon}, {@code lastResolvedCard} and
 * {@code score} are null when absent ({@code score} is set only once the
 * game is over).
 *
 * @param dungeon               the face-down pile, top first; copied, so the caller's list
 *                              is never shared
 * @param room                  the face-up cards of the current room, at most the ruleset's
 *                              room size; copied like {@code dungeon}
 * @param weapon                the equipped weapon and the monsters it has slain, or null
 *                              when barehanded
 * @param health                current life, never above the ruleset's cap; zero or below
 *                              once the game is lost, kept raw for the loss score
 * @param potionsUsedThisRoom   potions that healed this turn (wasted ones are not counted);
 *                              back to 0 when the next room is dealt
 * @param cardsResolvedThisTurn cards resolved from the current room so far; 0 right after a
 *                              deal or an avoid
 * @param previousRoomAvoided   whether the room before this one was avoided, which forbids
 *                              avoiding this one under the standard rule
 * @param lastResolvedCard      the card most recently resolved, or null before the first;
 *                              the win score reads it
 * @param status                whether the game is running, won or lost
 * @param score                 the final score, or null while {@code status} is
 *                              {@link Status#IN_PROGRESS}
 */
public record GameState(
        List<Card> dungeon,
        List<Card> room,
        EquippedWeapon weapon,
        int health,
        int potionsUsedThisRoom,
        int cardsResolvedThisTurn,
        boolean previousRoomAvoided,
        Card lastResolvedCard,
        Status status,
        Integer score) {

    /**
     * Copies both piles, so no caller can change a state after the fact.
     *
     * @throws NullPointerException if {@code dungeon} or {@code room} is null, or holds a null
     */
    public GameState {
        dungeon = List.copyOf(dungeon);
        room = List.copyOf(room);
    }

    /**
     * True once any card in the current room has been resolved; gates avoiding.
     *
     * @return whether {@code cardsResolvedThisTurn} is above zero
     */
    public boolean roomResolutionStarted() {
        return cardsResolvedThisTurn > 0;
    }

    /**
     * How many monsters are still face-down in the dungeon.
     *
     * <p>The same cards a loss score is charged for — the room's are not
     * counted, nor the weapons and potions down there with them. It is the one
     * figure that explains a death score, which is otherwise an unexplained
     * negative number on the run-end panel.
     *
     * @return the count of monster cards in {@code dungeon}, 0 or more
     */
    public int monstersRemaining() {
        return (int) dungeon.stream().filter(card -> card.type() == CardType.MONSTER).count();
    }
}
