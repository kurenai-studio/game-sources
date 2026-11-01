package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;

import java.util.Locale;

/**
 * Maps a card to the sprite region drawn for it. The delivered art names its
 * regions {@code creature_<value>_<name>_<suit>}, {@code weapon_<value>_<name>}
 * and {@code potion_<value>_<name>}, with the value zero-padded and the
 * creature's suit taken from the card's id.
 *
 * <p>Pure string work, so the whole 44-card mapping is provable headlessly —
 * the failure it guards against is a card quietly showing the wrong creature.
 */
final class CardSprites {

    /** Creature names by ordered value; index 0 is value 2. */
    private static final String[] CREATURES = {
        "cellar_rat", "carrion_bat", "grave_slime", "bone_crawler", "goblin_cutter",
        "ghoul", "tomb_spider", "gaunt_knight", "deep_ogre", "flayed_priest",
        "widow_queen", "warden", "the_debt",
    };

    /** Weapon names by value; index 0 is value 2. */
    private static final String[] WEAPONS = {
        "rusted_shiv", "iron_nail", "hatchet", "short_sword", "mace",
        "broadsword", "war_pick", "broadaxe", "greatsword",
    };

    /** Potion names by value; index 0 is value 2. */
    private static final String[] POTIONS = {
        "dram", "vial", "phial", "draught", "flask",
        "carafe", "decanter", "amphora", "flagon",
    };

    private CardSprites() {
    }

    /**
     * The base region for a card — frame 1 of its idle cycle, pixel-identical.
     *
     * @param card a card of the standard deck's values
     * @return the atlas region name, e.g. {@code creature_12_<name>_spades} or
     *         {@code weapon_07_<name>}; the value is zero-padded to two digits
     */
    static String regionName(Card card) {
        int value = card.value();
        return switch (card.type()) {
            case MONSTER -> "creature_" + pad(value) + "_" + name(CREATURES, value) + "_" + suit(card);
            case WEAPON -> "weapon_" + pad(value) + "_" + name(WEAPONS, value);
            case POTION -> "potion_" + pad(value) + "_" + name(POTIONS, value);
        };
    }

    /**
     * What to call this card on screen — {@code BROADAXE}, {@code DEEP OGRE}.
     * Read back out of the region name, so the name the rail shows and the
     * sprite beside it can never disagree.
     *
     * @param card a card of the standard deck's values
     * @return the card's name, upper-cased, words separated by spaces, without a suit
     */
    static String displayName(Card card) {
        String region = regionName(card);
        int from = region.indexOf('_', region.indexOf('_') + 1) + 1;
        String name = region.substring(from);
        if (card.type() == CardType.MONSTER) {
            name = name.substring(0, name.lastIndexOf('_')); // drop the suit
        }
        return name.replace('_', ' ').toUpperCase(Locale.ROOT);
    }

    /**
     * The stem to pass to {@code atlas.findRegions}, which returns the five idle
     * frames in index order.
     *
     * @param card a card of the standard deck's values
     * @return the region name with {@code _idle} appended
     */
    static String idleStem(Card card) {
        return regionName(card) + "_idle";
    }

    /**
     * Clubs or spades, read from the card's id rather than anything derived —
     * the two suits are separate drawings, not a runtime recolour.
     */
    private static String suit(Card card) {
        return card.id().endsWith("C") ? "clubs" : "spades";
    }

    private static String name(String[] names, int value) {
        int index = value - 2;
        if (index < 0 || index >= names.length) {
            throw new IllegalArgumentException("no sprite for value " + value);
        }
        return names[index];
    }

    private static String pad(int value) {
        return value < 10 ? "0" + value : String.valueOf(value);
    }
}
