package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static com.tomer.scoundrel.rules.Cards.card;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The standard 44-card deck: what is in it, what is removed, and each card's value. */
class StandardDeckTest {

    private final List<Card> deck = new StandardDeck().cards().stream()
            .map(CardDefinition::card)
            .toList();

    /** The deck holds 44 cards. */
    @Test
    void deckHasExactly44Cards() {
        assertEquals(44, deck.size());
    }

    /** It splits into 26 monsters, 9 weapons and 9 potions. */
    @Test
    void deckHas26Monsters9Weapons9Potions() {
        Map<CardType, Long> counts = deck.stream()
                .collect(Collectors.groupingBy(Card::type, Collectors.counting()));
        assertEquals(26, counts.get(CardType.MONSTER));
        assertEquals(9, counts.get(CardType.WEAPON));
        assertEquals(9, counts.get(CardType.POTION));
    }

    /** The weapons are exactly the diamonds 2 to 10. */
    @Test
    void weaponsAreExactlyDiamonds2Through10() {
        Set<String> weaponIds = deck.stream()
                .filter(c -> c.type() == CardType.WEAPON)
                .map(Card::id)
                .collect(Collectors.toSet());
        assertEquals(Set.of("2D", "3D", "4D", "5D", "6D", "7D", "8D", "9D", "10D"), weaponIds);
        deck.stream().filter(c -> c.type() == CardType.WEAPON)
                .forEach(c -> assertTrue(c.value() >= 2 && c.value() <= 10));
    }

    /** The potions are exactly the hearts 2 to 10. */
    @Test
    void potionsAreExactlyHearts2Through10() {
        Set<String> potionIds = deck.stream()
                .filter(c -> c.type() == CardType.POTION)
                .map(Card::id)
                .collect(Collectors.toSet());
        assertEquals(Set.of("2H", "3H", "4H", "5H", "6H", "7H", "8H", "9H", "10H"), potionIds);
        deck.stream().filter(c -> c.type() == CardType.POTION)
                .forEach(c -> assertTrue(c.value() >= 2 && c.value() <= 10));
    }

    /** The monsters are clubs and spades, two of each value from 2 to 14. */
    @Test
    void monstersAreClubsAndSpadesTwoOfEachValue2Through14() {
        List<Card> monsters = deck.stream().filter(c -> c.type() == CardType.MONSTER).toList();
        Map<Integer, Long> byValue = monsters.stream()
                .collect(Collectors.groupingBy(Card::value, Collectors.counting()));
        for (int value = 2; value <= 14; value++) {
            assertEquals(2, byValue.get(value), "monsters of value " + value);
        }
        monsters.forEach(c -> assertTrue(c.id().endsWith("C") || c.id().endsWith("S"), c.id()));
    }

    /** The red face cards, red aces and jokers are gone, and nothing outside the spec is present. */
    @Test
    void removedCardsAreAbsent() {
        Set<String> ids = deck.stream().map(Card::id).collect(Collectors.toSet());
        // red face cards, red aces, jokers
        for (String removed : List.of("JH", "QH", "KH", "AH", "JD", "QD", "KD", "AD", "JOKER1", "JOKER2")) {
            assertTrue(!ids.contains(removed), removed + " must not be in the deck");
        }
        // nothing outside hearts/diamonds 2-10 and clubs/spades 2-A
        for (Card c : deck) {
            String suit = c.id().substring(c.id().length() - 1);
            if (suit.equals("H") || suit.equals("D")) {
                assertTrue(c.value() >= 2 && c.value() <= 10, c.id());
            } else {
                assertTrue(suit.equals("C") || suit.equals("S"), c.id());
                assertTrue(c.value() >= 2 && c.value() <= 14, c.id());
            }
        }
    }

    /** No two cards share an id. */
    @Test
    void allCardIdsAreUnique() {
        assertEquals(44, deck.stream().map(Card::id).distinct().count());
    }

    /** Monster values run 2 to 10, then J 11, Q 12, K 13 and A 14. */
    @Test
    void monsterValuesIncludeFaceCardMapping() {
        assertEquals(2, card("2C").value());
        assertEquals(10, card("10S").value());
        assertEquals(11, card("JC").value());
        assertEquals(12, card("QS").value());
        assertEquals(13, card("KC").value());
        assertEquals(14, card("AS").value());
    }

    /** A weapon's value is its number. */
    @Test
    void weaponValuesMatchTheirNumber() {
        assertEquals(2, card("2D").value());
        assertEquals(10, card("10D").value());
        assertEquals(CardType.WEAPON, card("2D").type());
    }

    /** A potion's value is its number. */
    @Test
    void potionValuesMatchTheirNumber() {
        assertEquals(2, card("2H").value());
        assertEquals(10, card("10H").value());
        assertEquals(CardType.POTION, card("10H").type());
    }
}
