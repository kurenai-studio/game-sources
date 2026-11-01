package com.tomer.scoundrel.audio;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** How a card's value maps to a light, medium or heavy sound, and the pitch nudge within each. */
class WeightTest {

    private static final float EPSILON = 1e-6f;

    /** Weapons 2–4 are light, 5–7 medium and 8–10 heavy. */
    @Test
    void weaponsSplitAfterFourAndAfterSeven() {
        assertEquals(Weight.LIGHT, Scale.WEAPON.weightOf(2));
        assertEquals(Weight.LIGHT, Scale.WEAPON.weightOf(4));
        assertEquals(Weight.MEDIUM, Scale.WEAPON.weightOf(5));
        assertEquals(Weight.MEDIUM, Scale.WEAPON.weightOf(7));
        assertEquals(Weight.HEAVY, Scale.WEAPON.weightOf(8));
        assertEquals(Weight.HEAVY, Scale.WEAPON.weightOf(10));
    }

    /** Potions split into weights exactly where weapons do. */
    @Test
    void potionsSplitWhereWeaponsDo() {
        for (int value = 2; value <= 10; value++) {
            assertEquals(Scale.WEAPON.weightOf(value), Scale.POTION.weightOf(value), "potion " + value);
        }
    }

    /** Monsters 2–5 are light, 6–10 medium and 11–14 heavy. */
    @Test
    void monstersSplitAfterFiveAndAfterTen() {
        assertEquals(Weight.LIGHT, Scale.MONSTER.weightOf(2));
        assertEquals(Weight.LIGHT, Scale.MONSTER.weightOf(5));
        assertEquals(Weight.MEDIUM, Scale.MONSTER.weightOf(6));
        assertEquals(Weight.MEDIUM, Scale.MONSTER.weightOf(10));
        assertEquals(Weight.HEAVY, Scale.MONSTER.weightOf(11));
        assertEquals(Weight.HEAVY, Scale.MONSTER.weightOf(14));
    }

    /** Damage up to 4 is light and anything more is heavy, never medium. */
    @Test
    void damageLetThroughIsLightUpToFourAndNeverMedium() {
        assertEquals(Weight.LIGHT, Scale.DAMAGE.weightOf(1));
        assertEquals(Weight.LIGHT, Scale.DAMAGE.weightOf(4));
        assertEquals(Weight.HEAVY, Scale.DAMAGE.weightOf(5));
        assertEquals(Weight.HEAVY, Scale.DAMAGE.weightOf(12));
        for (int damage = 1; damage <= 20; damage++) {
            assertNotEquals(Weight.MEDIUM, Scale.DAMAGE.weightOf(damage), "damage " + damage);
        }
    }

    /** A value outside the deck takes the weight at the nearest edge. */
    @Test
    void valuesOutsideTheDeckTakeTheNearestEdgeWeight() {
        // A future card definition may carry a value the standard deck never
        // deals; it should still sound like something rather than fail.
        assertEquals(Weight.LIGHT, Scale.WEAPON.weightOf(0));
        assertEquals(Weight.HEAVY, Scale.WEAPON.weightOf(99));
        assertEquals(Weight.LIGHT, Scale.MONSTER.weightOf(1));
        assertEquals(Weight.HEAVY, Scale.MONSTER.weightOf(15));
    }

    /** The middle value of a weight plays at unchanged pitch. */
    @Test
    void pitchIsUnchangedAtTheMiddleOfAWeight() {
        assertEquals(1f, Scale.WEAPON.pitchOf(3), EPSILON);
        assertEquals(1f, Scale.WEAPON.pitchOf(6), EPSILON);
        assertEquals(1f, Scale.WEAPON.pitchOf(9), EPSILON);
        assertEquals(1f, Scale.MONSTER.pitchOf(8), EPSILON);
    }

    /** A weight's lightest value is nudged up in pitch and its heaviest down, by {@code NUDGE}. */
    @Test
    void theLightestValueOfAWeightIsNudgedUpAndTheHeaviestDown() {
        assertEquals(1f + Scale.NUDGE, Scale.WEAPON.pitchOf(2), EPSILON);
        assertEquals(1f - Scale.NUDGE, Scale.WEAPON.pitchOf(4), EPSILON);
        assertEquals(1f + Scale.NUDGE, Scale.MONSTER.pitchOf(11), EPSILON);
        assertEquals(1f - Scale.NUDGE, Scale.MONSTER.pitchOf(14), EPSILON);
    }

    /** Within each weight, pitch falls strictly as the value rises. */
    @Test
    void pitchFallsStrictlyAsValueRisesWithinEachWeight() {
        for (Scale scale : Scale.values()) {
            for (int value = scale.min; value < scale.max; value++) {
                if (scale.weightOf(value) == scale.weightOf(value + 1)) {
                    assertTrue(scale.pitchOf(value + 1) < scale.pitchOf(value),
                            scale + " " + value + " -> " + (value + 1));
                }
            }
        }
    }

    /** Crossing into the next weight starts the nudge high again. */
    @Test
    void eachWeightStartsItsNudgeAfresh() {
        // The weight already says "heavier"; the nudge only separates cards
        // that share one, so crossing into the next weight starts high again.
        assertEquals(1f - Scale.NUDGE, Scale.WEAPON.pitchOf(4), EPSILON);
        assertEquals(1f + Scale.NUDGE, Scale.WEAPON.pitchOf(5), EPSILON);
    }

    /** A value outside the deck takes the pitch of the nearest edge value. */
    @Test
    void pitchOutsideTheDeckClampsToTheEdgeValue() {
        assertEquals(Scale.WEAPON.pitchOf(2), Scale.WEAPON.pitchOf(0), EPSILON);
        assertEquals(Scale.WEAPON.pitchOf(10), Scale.WEAPON.pitchOf(99), EPSILON);
    }

    /** A weight that holds a single value leaves the pitch unchanged. */
    @Test
    void aWeightHoldingOneValueLeavesThePitchAlone() {
        assertEquals(1f, Scale.pitchWithin(7, 7, 7), EPSILON);
    }

    /** Weights appear in file names in lower case. */
    @Test
    void weightsAreNamedInFilesInLowerCase() {
        assertEquals("light", Weight.LIGHT.fileName());
        assertEquals("medium", Weight.MEDIUM.fileName());
        assertEquals("heavy", Weight.HEAVY.fileName());
    }
}
