package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.rules.Move;

/**
 * Short UI labels, pure so they are unit tested: a card's rank and type, the
 * chooser button text for a move, the trophy-rail plate describing how much bite
 * the equipped weapon has left, the end screen's score breakdown, the
 * Tutorial-complete line that reads a winning score back as its scoring rule, and
 * the hint under the title's volume plates.
 */
final class Labels {

    private Labels() {
    }

    /**
     * The playing-card rank shown in a card's header. The footer carries the
     * ordered value instead, so a Queen reads Q above 12 — the one place the
     * game says out loud what a face card is worth.
     *
     * @param value the card's value, 2–14
     * @return {@code J}, {@code Q}, {@code K} or {@code A} for 11–14, else the number
     */
    static String rank(int value) {
        return switch (value) {
            case 11 -> "J";
            case 12 -> "Q";
            case 13 -> "K";
            case 14 -> "A";
            default -> String.valueOf(value);
        };
    }

    /**
     * The type stamped in the card's header, opposite its rank.
     *
     * @param type the card's type
     * @return the type's name, upper-cased
     */
    static String cardType(CardType type) {
        return switch (type) {
            case MONSTER -> "MONSTER";
            case WEAPON -> "WEAPON";
            case POTION -> "POTION";
        };
    }

    /**
     * Chooser button text for a move.
     *
     * @param move a legal move
     * @return a verb or two in sentence case, e.g. {@code Use weapon}
     */
    static String move(Move move) {
        return switch (move) {
            case Move.FightWithWeapon ignored -> "Use weapon";
            case Move.FightBarehanded ignored -> "Barehanded";
            case Move.TakeWeapon ignored -> "Equip";
            case Move.TakePotion ignored -> "Drink";
            case Move.AvoidRoom ignored -> "Avoid";
        };
    }

    /**
     * The trophy-rail plate: {@code slays anything} fresh, {@code slays < N}, or {@code spent}.
     *
     * @param weapon the equipped weapon
     * @return {@code spent} once the threshold is 2, since nothing is below a 2
     */
    static String weaponThreshold(EquippedWeapon weapon) {
        if (weapon.threshold().isEmpty()) {
            return "slays anything";
        }
        int threshold = weapon.threshold().getAsInt();
        return threshold <= 2 ? "spent" : "slays < " + threshold;
    }

    /**
     * The line under the end-screen score, naming where that number came from —
     * the death score especially, which charges you for monsters still in the
     * face-down dungeon that the player never saw. The penalty needs no extra
     * state: {@code StandardScoring} makes it exactly {@code health - score}.
     *
     * @param score     the final score
     * @param health    the health the run ended on
     * @param healthCap the ruleset's cap, for the potion-bonus win
     * @param won       whether the dungeon was cleared
     * @return the breakdown, in lower case
     */
    static String scoreBreakdown(int score, int health, int healthCap, boolean won) {
        if (!won) {
            int monstersLeft = health - score;
            return monstersLeft == 0
                    ? health + " health, an empty dungeon"
                    : health + " health, minus " + monstersLeft + " still in the dungeon";
        }
        if (score > healthCap) {
            return healthCap + " at the cap + the " + (score - healthCap) + " you finished on";
        }
        return "the health you kept";
    }

    /**
     * The Tutorial-complete line: a winning score read back as the rule that
     * produced it, then the losing rule as a parting recap. Covers both of
     * {@code StandardScoring}'s win branches — the health you kept, or the cap
     * plus the potion you finished on when the score runs over the cap.
     *
     * @param score     the tutorial's winning score
     * @param healthCap the ruleset's cap
     * @return two sentences: the winning rule, then the losing one
     */
    static String tutorialScore(int score, int healthCap) {
        String win = score > healthCap
                ? "You ended at a full " + healthCap + " on a potion, so it scores "
                        + healthCap + " + " + (score - healthCap) + " — the only way past "
                        + healthCap + "."
                : "A cleared dungeon scores the health you kept — your " + score + ".";
        return win + " Die instead and the score goes negative: your health, minus every "
                + "monster still left in the dungeon.";
    }

    /**
     * The line under the title's volume plates. Always there, because nothing
     * else says M exists; muted, it says why everything has gone quiet.
     *
     * @param muted whether everything is muted now
     * @return the hint, upper-cased
     */
    static String muteHint(boolean muted) {
        return muted ? "MUTED · M TO UNMUTE" : "M TO MUTE ALL";
    }
}
