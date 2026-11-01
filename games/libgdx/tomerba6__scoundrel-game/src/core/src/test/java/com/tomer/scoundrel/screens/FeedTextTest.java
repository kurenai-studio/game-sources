package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.rules.GameEvent;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * The event feed's text, word for word: the one-liners the player reads as a
 * move resolves. Pinning the wording makes any change to it deliberate.
 */
class FeedTextTest {

    private static Card monster(String id, int value) {
        return new Card(id, CardType.MONSTER, value);
    }

    private static Card weapon(String id, int value) {
        return new Card(id, CardType.WEAPON, value);
    }

    private static Card potion(String id, int value) {
        return new Card(id, CardType.POTION, value);
    }

    /** A bare-handed kill reads as a fight, with the full value taken. */
    @Test
    void barehandedKillReadsTheFullValueTaken() {
        assertEquals("Fought the Queen of clubs barehanded — took 12",
                FeedText.line(new GameEvent.MonsterDefeated(monster("QC", 12), false, 12)));
    }

    /** A weapon kill reads the damage taken, or "unharmed". */
    @Test
    void weaponKillReadsTheDamageOrUnharmed() {
        assertEquals("Slew the 7 of spades — took 2",
                FeedText.line(new GameEvent.MonsterDefeated(monster("7S", 7), true, 2)));
        assertEquals("Slew the 6 of clubs — unharmed",
                FeedText.line(new GameEvent.MonsterDefeated(monster("6C", 6), true, 0)));
    }

    /** A potion reads the health healed, or "already full". */
    @Test
    void potionReadsHealedOrAlreadyFull() {
        assertEquals("Drank the 4 of hearts — healed 4",
                FeedText.line(new GameEvent.PotionUsed(potion("4H", 4), 4)));
        assertEquals("Drank the 3 of hearts — already full",
                FeedText.line(new GameEvent.PotionUsed(potion("3H", 3), 0)));
    }

    /** A wasted potion reads "one potion a turn". */
    @Test
    void wastedPotionReadsOnePotionATurn() {
        assertEquals("the 3 of hearts wasted — one potion a turn",
                FeedText.line(new GameEvent.PotionWasted(potion("3H", 3))));
    }

    /** Equipping a weapon names the card. */
    @Test
    void weaponEquipReadsTheCard() {
        assertEquals("Equipped the 5 of diamonds",
                FeedText.line(new GameEvent.WeaponEquipped(weapon("5D", 5))));
    }

    /** A dulled weapon reads its new threshold, or "spent" at 2. */
    @Test
    void weaponDegradeReadsTheThresholdOrSpent() {
        assertEquals("The weapon dulls — slays < 6",
                FeedText.line(new GameEvent.WeaponDegraded(weapon("5D", 5), 6)));
        assertEquals("The weapon is spent",
                FeedText.line(new GameEvent.WeaponDegraded(weapon("5D", 5), 2)));
    }

    /** Avoiding reads "Avoided the room". */
    @Test
    void avoidReadsAvoidedTheRoom() {
        assertEquals("Avoided the room", FeedText.line(new GameEvent.RoomAvoided(List.of())));
    }

    /** A deal, a win and a loss have no feed line. */
    @Test
    void eventsTheBoardAlreadyShowsHaveNoLine() {
        assertNull(FeedText.line(new GameEvent.RoomDealt(List.of())));
        assertNull(FeedText.line(new GameEvent.GameWon(20)));
        assertNull(FeedText.line(new GameEvent.GameLost(-5)));
    }

    /** A card is named by its rank, face cards in words, and its suit. */
    @Test
    void cardNameNamesEveryRankAndSuit() {
        assertEquals("the Ace of spades", FeedText.cardName(monster("AS", 14)));
        assertEquals("the King of clubs", FeedText.cardName(monster("KC", 13)));
        assertEquals("the Queen of spades", FeedText.cardName(monster("QS", 12)));
        assertEquals("the Jack of clubs", FeedText.cardName(monster("JC", 11)));
        assertEquals("the 10 of diamonds", FeedText.cardName(weapon("10D", 10)));
        assertEquals("the 2 of hearts", FeedText.cardName(potion("2H", 2)));
    }

    /** A card whose id has no known suit is named by its type and value. */
    @Test
    void cardNameFallsBackToTypeAndValueForAnUnrecognisedId() {
        // Defensive branch: a card whose id ends in no known suit letter.
        assertEquals("monster 2", FeedText.cardName(monster("2X", 2)));
    }

    /** M during a run says what it did, since there is nothing else to see. */
    @Test
    void theMuteKeySaysWhetherTheSoundIsOffOrOn() {
        assertEquals("Sound off", FeedText.mute(true));
        assertEquals("Sound on", FeedText.mute(false));
    }
}
