package com.tomer.scoundrel.tutorial;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.rules.Move;

import java.util.List;

/**
 * The scripted first-run: a curated dungeon (played through the engine's exact
 * ordered-deck entry) and the beats that narrate it. The deck is arranged so
 * every rule surfaces in turn — bare-handed and armed combat, weapon
 * degradation both ways, a weapon upgrade, potion healing and the one-per-turn
 * cap, avoiding (and not twice in a row) — and the run ends in a win with
 * health to spare. Scoring is taught in two beats where it bites: the negative
 * losing score after the run's heaviest blow, and what a cleared dungeon is
 * worth with the last monster still standing.
 */
public final class TutorialScript {

    private TutorialScript() {
    }

    private static Card monster(String id, int value) {
        return new Card(id, CardType.MONSTER, value);
    }

    private static Card weapon(String id, int value) {
        return new Card(id, CardType.WEAPON, value);
    }

    private static Card potion(String id, int value) {
        return new Card(id, CardType.POTION, value);
    }

    private static final Card M2C = monster("2C", 2);
    private static final Card W5D = weapon("5D", 5);
    private static final Card M7S = monster("7S", 7);
    private static final Card M6C = monster("6C", 6);
    private static final Card P4H = potion("4H", 4);
    private static final Card P3H = potion("3H", 3);
    private static final Card M9S = monster("9S", 9);
    private static final Card M2S = monster("2S", 2);
    private static final Card M3C = monster("3C", 3);
    private static final Card W10D = weapon("10D", 10);
    private static final Card M4S = monster("4S", 4);
    private static final Card P5H = potion("5H", 5);
    private static final Card M3S = monster("3S", 3);
    private static final Card P2H = potion("2H", 2);

    private static final List<Card> DECK = List.of(
            M2C, W5D, M7S, M6C, P4H, P3H, M9S, M2S, M3C, W10D, M4S, P5H, M3S, P2H);

    private static final List<TutorialStep> STEPS = List.of(
            TutorialStep.say("Welcome. You start with 20 health, and you win by clearing the "
                    + "whole dungeon. Cards come four at a time — a room; you resolve three and "
                    + "the fourth carries into the next room."),
            TutorialStep.act("Clubs and spades are monsters. Fought bare-handed, you take a "
                    + "monster's full value as damage. Fight this 2.", new Move.FightBarehanded(M2C)),
            TutorialStep.act("Diamonds are weapons. Equip this 5 — now monsters cost you their "
                    + "value minus the weapon's.", new Move.TakeWeapon(W5D)),
            TutorialStep.act("Fight the 7 with the weapon. You take only 7 - 5 = 2.",
                    new Move.FightWithWeapon(M7S)),
            TutorialStep.say("A weapon dulls as it kills: afterward it can only strike monsters "
                    + "weaker than its last kill. Yours just slew a 7."),
            TutorialStep.act("The 6 is weaker than 7, so the weapon still bites. Strike it.",
                    new Move.FightWithWeapon(M6C)),
            TutorialStep.act("Hearts are potions. Drink the 4 to heal.", new Move.TakePotion(P4H)),
            TutorialStep.act("Only the first potion each turn heals — a second is wasted. Drink "
                    + "this one and watch.", new Move.TakePotion(P3H)),
            TutorialStep.say("Your weapon last slew a 6, so it can no longer touch anything 6 or "
                    + "higher."),
            TutorialStep.act("This 9 is beyond the weapon's reach — you must fight it bare-handed.",
                    new Move.FightBarehanded(M9S)),
            TutorialStep.say("Half your health, gone in one blow. Had it killed you, your score "
                    + "would go negative: your health, minus every monster still waiting in the "
                    + "dungeon. Falling early with the deck still fat is the worst score there "
                    + "is — dying on the last room barely stings."),
            TutorialStep.act("A new weapon replaces the old one and everything stacked on it. "
                    + "Equip this 10.", new Move.TakeWeapon(W10D)),
            TutorialStep.act("Fresh and sharp, the 10 cuts the 3 down for free.",
                    new Move.FightWithWeapon(M3C)),
            TutorialStep.say("Some rooms aren't worth the blood. You can scoop a whole room to "
                    + "the bottom of the dungeon instead of fighting it."),
            TutorialStep.act("Avoid this room.", new Move.AvoidRoom()),
            TutorialStep.say("But never twice in a row — notice Avoid is greyed out now. Face "
                    + "this room."),
            TutorialStep.act("The 2 is within reach of your weapon. Slay it.",
                    new Move.FightWithWeapon(M2S)),
            TutorialStep.act("Top yourself up — drink the 2.", new Move.TakePotion(P2H)),
            TutorialStep.act("The 4 is out of the weapon's reach again — bare-handed.",
                    new Move.FightBarehanded(M4S)),
            TutorialStep.act("Nearly clear. Drink the 5.", new Move.TakePotion(P5H)),
            TutorialStep.say("One monster left, so the other half of scoring matters now. Clear "
                    + "the dungeon and your score is simply the health you keep — every point you "
                    + "don't spend is a point scored. One flourish: end at a full 20 with a potion "
                    + "as your very last card and it scores 20 plus that potion, the only way "
                    + "past 20."),
            TutorialStep.act("Finish the last monster to clear the dungeon.",
                    new Move.FightBarehanded(M3S)));

    /**
     * The curated dungeon, top card first, for {@code engine.newGame(...)}.
     *
     * @return an unmodifiable list of 14 cards, played under the standard ruleset
     * @see com.tomer.scoundrel.rules.ScoundrelEngine#newGame(List)
     */
    public static List<Card> deck() {
        return DECK;
    }

    /**
     * The ordered beats — a mix of explanation and gated action steps.
     *
     * @return an unmodifiable list, in the order the guide walks it
     */
    public static List<TutorialStep> steps() {
        return STEPS;
    }
}
