package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.CardType;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * The standard 44-card Scoundrel deck: monsters are all clubs and spades
 * (2–10 face value, J=11, Q=12, K=13, A=14), weapons the diamonds 2–10,
 * potions the hearts 2–10. Ids are rank + suit letter, e.g. "QS", "10D", "7H".
 */
public final class StandardDeck implements DeckDefinition {

    private final List<CardDefinition> cards;
    private final Map<String, CardDefinition> byId;

    /**
     * Builds the 44 definitions — clubs then spades 2–A, diamonds 2–10, hearts 2–10 — with
     * one shared effect per type, and indexes them by id.
     */
    public StandardDeck() {
        CardEffect monster = new MonsterEffect();
        CardEffect weapon = new WeaponEffect();
        CardEffect potion = new PotionEffect();
        List<CardDefinition> defs = new ArrayList<>();
        for (String suit : List.of("C", "S")) {
            for (int value = 2; value <= 14; value++) {
                defs.add(new CardDefinition(rank(value) + suit, CardType.MONSTER, value, monster));
            }
        }
        for (int value = 2; value <= 10; value++) {
            defs.add(new CardDefinition(value + "D", CardType.WEAPON, value, weapon));
        }
        for (int value = 2; value <= 10; value++) {
            defs.add(new CardDefinition(value + "H", CardType.POTION, value, potion));
        }
        this.cards = List.copyOf(defs);
        this.byId = cards.stream()
                .collect(Collectors.toUnmodifiableMap(CardDefinition::id, Function.identity()));
    }

    @Override
    public List<CardDefinition> cards() {
        return cards;
    }

    @Override
    public CardDefinition definition(String cardId) {
        CardDefinition def = byId.get(cardId);
        if (def == null) {
            throw new IllegalArgumentException("Unknown card id: " + cardId);
        }
        return def;
    }

    private static String rank(int value) {
        return switch (value) {
            case 11 -> "J";
            case 12 -> "Q";
            case 13 -> "K";
            case 14 -> "A";
            default -> String.valueOf(value);
        };
    }
}
