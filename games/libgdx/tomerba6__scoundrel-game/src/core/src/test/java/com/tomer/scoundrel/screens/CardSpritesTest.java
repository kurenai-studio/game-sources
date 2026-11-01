package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.rules.CardDefinition;
import com.tomer.scoundrel.rules.StandardDeck;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The card → sprite-region naming contract. The expected names below
 * are transcribed from the delivery manifest rather than generated, so this is
 * a real check of the mapping and not the mapping restating itself.
 */
class CardSpritesTest {

    /** Every base region the art ships, exactly as delivered. */
    private static final Set<String> DELIVERED = new TreeSet<>(List.of(
            "creature_02_cellar_rat_clubs", "creature_02_cellar_rat_spades",
            "creature_03_carrion_bat_clubs", "creature_03_carrion_bat_spades",
            "creature_04_grave_slime_clubs", "creature_04_grave_slime_spades",
            "creature_05_bone_crawler_clubs", "creature_05_bone_crawler_spades",
            "creature_06_goblin_cutter_clubs", "creature_06_goblin_cutter_spades",
            "creature_07_ghoul_clubs", "creature_07_ghoul_spades",
            "creature_08_tomb_spider_clubs", "creature_08_tomb_spider_spades",
            "creature_09_gaunt_knight_clubs", "creature_09_gaunt_knight_spades",
            "creature_10_deep_ogre_clubs", "creature_10_deep_ogre_spades",
            "creature_11_flayed_priest_clubs", "creature_11_flayed_priest_spades",
            "creature_12_widow_queen_clubs", "creature_12_widow_queen_spades",
            "creature_13_warden_clubs", "creature_13_warden_spades",
            "creature_14_the_debt_clubs", "creature_14_the_debt_spades",
            "weapon_02_rusted_shiv", "weapon_03_iron_nail", "weapon_04_hatchet",
            "weapon_05_short_sword", "weapon_06_mace", "weapon_07_broadsword",
            "weapon_08_war_pick", "weapon_09_broadaxe", "weapon_10_greatsword",
            "potion_02_dram", "potion_03_vial", "potion_04_phial",
            "potion_05_draught", "potion_06_flask", "potion_07_carafe",
            "potion_08_decanter", "potion_09_amphora", "potion_10_flagon"));

    private static Card card(CardDefinition def) {
        return new Card(def.id(), def.type(), def.value());
    }

    /**
     * The load-bearing one: every card the standard deck can deal resolves to a
     * region that was actually drawn, and no two cards share one. A missing name
     * would draw nothing; a shared one would show the wrong creature.
     */
    @Test
    void everyCardInTheDeckMapsToADeliveredRegionAndNoTwoShareOne() {
        Set<String> used = new HashSet<>();
        for (CardDefinition def : new StandardDeck().cards()) {
            String region = CardSprites.regionName(card(def));
            assertTrue(DELIVERED.contains(region),
                    "card " + def.id() + " maps to '" + region + "', which was never drawn");
            assertTrue(used.add(region),
                    "card " + def.id() + " reuses region '" + region + "'");
        }
        assertEquals(44, used.size(), "the 44-card deck should use 44 distinct regions");
    }

    /** Nothing was drawn that no card can ever show. */
    @Test
    void everyDeliveredRegionIsReachableFromSomeCard() {
        Set<String> used = new HashSet<>();
        for (CardDefinition def : new StandardDeck().cards()) {
            used.add(CardSprites.regionName(card(def)));
        }
        Set<String> orphans = new TreeSet<>(DELIVERED);
        orphans.removeAll(used);
        assertTrue(orphans.isEmpty(), "art with no card to show it: " + orphans);
    }

    /** Region names zero-pad the rank and give face cards their ordered value. */
    @Test
    void ranksAreZeroPaddedAndFacesUseTheirOrderedValue() {
        assertEquals("creature_02_cellar_rat_clubs", CardSprites.regionName(new Card("2C", CardType.MONSTER, 2)));
        assertEquals("creature_10_deep_ogre_spades", CardSprites.regionName(new Card("10S", CardType.MONSTER, 10)));
        assertEquals("creature_11_flayed_priest_clubs", CardSprites.regionName(new Card("JC", CardType.MONSTER, 11)));
        assertEquals("creature_12_widow_queen_spades", CardSprites.regionName(new Card("QS", CardType.MONSTER, 12)));
        assertEquals("creature_13_warden_clubs", CardSprites.regionName(new Card("KC", CardType.MONSTER, 13)));
        assertEquals("creature_14_the_debt_spades", CardSprites.regionName(new Card("AS", CardType.MONSTER, 14)));
    }

    /** A creature's suit comes from its card id. */
    @Test
    void theSuitComesFromTheCardIdNotItsValue() {
        assertEquals("creature_07_ghoul_clubs", CardSprites.regionName(new Card("7C", CardType.MONSTER, 7)));
        assertEquals("creature_07_ghoul_spades", CardSprites.regionName(new Card("7S", CardType.MONSTER, 7)));
    }

    /** Weapon and potion regions carry no suit. */
    @Test
    void weaponsAndPotionsIgnoreSuitEntirely() {
        assertEquals("weapon_05_short_sword", CardSprites.regionName(new Card("5D", CardType.WEAPON, 5)));
        assertEquals("potion_09_amphora", CardSprites.regionName(new Card("9H", CardType.POTION, 9)));
    }

    /**
     * The idle stem is the base name plus {@code _idle}, so
     * {@code findRegions} returns the five frames in order.
     */
    @Test
    void theIdleStemIsTheBaseNamePlusIdle() {
        Card rat = new Card("2C", CardType.MONSTER, 2);
        assertEquals(CardSprites.regionName(rat) + "_idle", CardSprites.idleStem(rat));
    }

    /**
     * The rail names the weapon it is holding. The art already carries that
     * name in its region, so it is read back from there rather than kept in a
     * second list that could drift out of step with the sprites.
     */
    @Test
    void theRailNameComesBackOutOfTheRegionName() {
        assertEquals("BROADAXE", CardSprites.displayName(new Card("9D", CardType.WEAPON, 9)));
        assertEquals("SHORT SWORD", CardSprites.displayName(new Card("5D", CardType.WEAPON, 5)));
        assertEquals("DEEP OGRE", CardSprites.displayName(new Card("10C", CardType.MONSTER, 10)));
        assertEquals("THE DEBT", CardSprites.displayName(new Card("AS", CardType.MONSTER, 14)));
        assertEquals("DRAUGHT", CardSprites.displayName(new Card("5H", CardType.POTION, 5)));
    }

    /** Every card has a display name in capitals and spaces. */
    @Test
    void everyCardCanNameItself() {
        for (CardDefinition def : new StandardDeck().cards()) {
            String name = CardSprites.displayName(card(def));
            assertTrue(name.matches("[A-Z ]+"), "bad display name: " + name);
        }
    }

    /** Every region name uses only lower-case letters, digits and underscores. */
    @Test
    void everyRegionNameIsLowercaseAlphanumericUnderscore() {
        // The atlas parses a trailing _<digits> as an animation index, so a
        // stray capital or dash here would silently change how it is grouped.
        for (CardDefinition def : new StandardDeck().cards()) {
            String region = CardSprites.regionName(card(def));
            assertTrue(region.matches("[a-z0-9_]+"), "bad region name: " + region);
        }
    }
}
