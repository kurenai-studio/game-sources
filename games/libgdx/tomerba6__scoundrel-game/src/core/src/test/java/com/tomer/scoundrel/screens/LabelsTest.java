package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.rules.Move;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The short UI labels, word for word: a card's rank and type, the chooser's move
 * names, the weapon plate, the score lines, and the mute hint. Pinning the
 * wording makes any change to it deliberate.
 */
class LabelsTest {

    private static Card monster(String id, int value) {
        return new Card(id, CardType.MONSTER, value);
    }

    private static final Card WEAPON = new Card("5D", CardType.WEAPON, 5);

    /** Each move has its chooser label: Use weapon, Barehanded, Equip, Drink, Avoid. */
    @Test
    void moveLabelsCoverEveryMove() {
        Card any = monster("7S", 7);
        assertEquals("Use weapon", Labels.move(new Move.FightWithWeapon(any)));
        assertEquals("Barehanded", Labels.move(new Move.FightBarehanded(any)));
        assertEquals("Equip", Labels.move(new Move.TakeWeapon(WEAPON)));
        assertEquals("Drink", Labels.move(new Move.TakePotion(new Card("4H", CardType.POTION, 4))));
        assertEquals("Avoid", Labels.move(new Move.AvoidRoom()));
    }

    /** A weapon that has slain nothing reads "slays anything". */
    @Test
    void aFreshWeaponSlaysAnything() {
        assertEquals("slays anything", Labels.weaponThreshold(new EquippedWeapon(WEAPON)));
    }

    /** A weapon that last slew a 6 reads "slays &lt; 6". */
    @Test
    void aWeaponReadsItsRemainingBite() {
        EquippedWeapon slewSix = new EquippedWeapon(WEAPON, List.of(monster("6C", 6)));
        assertEquals("slays < 6", Labels.weaponThreshold(slewSix));
    }

    /** A weapon that last slew a 2 reads "spent". */
    @Test
    void aWeaponThatSlewATwoIsSpent() {
        EquippedWeapon slewTwo = new EquippedWeapon(WEAPON, List.of(monster("2S", 2)));
        assertEquals("spent", Labels.weaponThreshold(slewTwo));
    }

    /** The tutorial's line for an ordinary win names the health kept and recaps the losing score. */
    @Test
    void anOrdinaryWinReadsAsTheHealthYouKept() {
        String blurb = Labels.tutorialScore(10, 20);
        assertTrue(blurb.contains("10"), blurb);
        assertTrue(blurb.contains("negative"), "it should recap the losing score too: " + blurb);
    }

    /** Same font limit as the tutorial narration — an unmapped glyph renders blank. */
    @Test
    void everyLabelUsesCharactersTheFontCanRender() {
        String extras = "—–×•"; // must track Theme.EXTRA_CHARS
        List<String> labels = List.of(
                Labels.scoreBreakdown(-174, -9, 20, false),
                Labels.scoreBreakdown(-2, -2, 20, false),
                Labels.scoreBreakdown(11, 11, 20, true),
                Labels.scoreBreakdown(24, 20, 20, true),
                Labels.tutorialScore(10, 20),
                Labels.tutorialScore(24, 20));
        for (String text : labels) {
            for (char c : text.toCharArray()) {
                boolean renderable = (c >= 0x20 && c <= 0x7E) || extras.indexOf(c) >= 0;
                assertTrue(renderable, "unrenderable U+"
                        + Integer.toHexString(c).toUpperCase() + " ('" + c + "') in: " + text);
            }
        }
    }

    /** A loss's breakdown names its final health and the monsters still in the dungeon. */
    @Test
    void aLossBreakdownNamesTheDungeonPenalty() {
        // ScoringTest's case: died at -3 with Q(12) + 9 face-down, scoring -24.
        // The penalty is recoverable from the pair: health - score = 21.
        String line = Labels.scoreBreakdown(-24, -3, 20, false);
        assertTrue(line.contains("-3"), line);
        assertTrue(line.contains("21"), "should name the 21 of monsters left: " + line);
    }

    /** A loss with nothing left in the dungeon names no penalty. */
    @Test
    void aLossOnTheLastCardHasNoDungeonPenaltyToName() {
        // Nothing left face-down, so "minus 0" would be noise.
        String line = Labels.scoreBreakdown(-2, -2, 20, false);
        assertTrue(line.contains("-2"), line);
        assertFalse(line.contains("0"), "should not read as a 0 penalty: " + line);
    }

    /** An ordinary win's breakdown reads "the health you kept". */
    @Test
    void anOrdinaryWinBreakdownIsJustTheHealthKept() {
        assertEquals("the health you kept", Labels.scoreBreakdown(11, 11, 20, true));
    }

    /** A win above the cap names the cap and the potion it finished on. */
    @Test
    void aWinBreakdownAboveTheCapNamesTheFinalPotion() {
        String line = Labels.scoreBreakdown(24, 20, 20, true);
        assertTrue(line.contains("20"), line);
        assertTrue(line.contains("4"), "should name the 4-potion it finished on: " + line);
    }

    /**
     * The tutorial's line for a score above the cap reads as the cap plus the
     * final potion, and recaps the losing score.
     */
    @Test
    void aScoreAboveTheCapReadsAsCapPlusTheFinalPotion() {
        // StandardScoring's other win branch: finish at the cap on a potion and
        // the score is cap + that potion — 20 + 4 here.
        String blurb = Labels.tutorialScore(24, 20);
        assertTrue(blurb.contains("20 + 4"), blurb);
        assertTrue(blurb.contains("negative"), "it should recap the losing score too: " + blurb);
    }

    /**
     * The card's header shows the playing-card rank, its footer the ordered
     * value the rules use — a Queen reads Q up top and 12 below, which is the
     * only place the game explains that mapping.
     */
    @Test
    void ranksReadAsPlayingCardsAboveTheirValue() {
        assertEquals("2", Labels.rank(2));
        assertEquals("10", Labels.rank(10));
        assertEquals("J", Labels.rank(11));
        assertEquals("Q", Labels.rank(12));
        assertEquals("K", Labels.rank(13));
        assertEquals("A", Labels.rank(14));
    }

    /** Every value from 2 to 14 has a rank. */
    @Test
    void everyDealtValueHasARank() {
        for (int value = 2; value <= 14; value++) {
            assertFalse(Labels.rank(value).isBlank(), "no rank for " + value);
        }
    }

    /** Each card type's header label is its name in upper case. */
    @Test
    void theTypeLabelIsTheOneInTheCardHeader() {
        assertEquals("MONSTER", Labels.cardType(CardType.MONSTER));
        assertEquals("WEAPON", Labels.cardType(CardType.WEAPON));
        assertEquals("POTION", Labels.cardType(CardType.POTION));
    }

    /**
     * The line under the title's volume plates is always there, since nothing
     * else says M exists; muted, it says why everything is quiet.
     */
    @Test
    void theLineUnderTheVolumePlatesTellsWhatMDoes() {
        assertEquals("M TO MUTE ALL", Labels.muteHint(false));
        assertEquals("MUTED · M TO UNMUTE", Labels.muteHint(true));
    }
}
