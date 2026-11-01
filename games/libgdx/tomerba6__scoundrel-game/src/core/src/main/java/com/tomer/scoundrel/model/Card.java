package com.tomer.scoundrel.model;

/**
 * A card in play. {@code type} and {@code value} are stamped from the card's
 * definition so the state stays plain and serializable; behavior is looked up
 * by {@code id} from the active deck definition at resolution time.
 *
 * @param id    the definition's id, unique within a deck (the standard deck uses rank
 *              plus suit letter: {@code "QS"}, {@code "10D"}); the key the effect is looked up by
 * @param type  which of the base categories the card belongs to
 * @param value its strength: 2–14 for a monster (J=11 … A=14), 2–10 for a weapon or potion
 */
public record Card(String id, CardType type, int value) {
}
