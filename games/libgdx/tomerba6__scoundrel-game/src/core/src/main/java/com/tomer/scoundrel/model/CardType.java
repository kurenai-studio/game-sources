package com.tomer.scoundrel.model;

/** The base Scoundrel card categories. Future special cards may add new ones. */
public enum CardType {
    /** Fought barehanded or with the weapon; its value is the damage it deals. */
    MONSTER,
    /** Equipped when taken, replacing the old weapon; its value is subtracted from a monster's. */
    WEAPON,
    /** Heals its value when taken, up to the cap and the turn's potion allowance. */
    POTION
}
