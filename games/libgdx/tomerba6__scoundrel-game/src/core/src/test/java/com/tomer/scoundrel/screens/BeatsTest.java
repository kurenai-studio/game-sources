package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Each sound's beat is read off the effect it belongs to, so these pin two things
 * at once: the moment (docs/audio.md's timing table, at 12 fps), and that it is
 * the moment the picture changes — a hair before the beat the effect has not got
 * there yet, a hair after it has. Move an animation and its sound moves with it;
 * these then say whether it still lands on the thing it is meant to.
 */
class BeatsTest {

    private static final float FRAME = 1f / 12f;
    private static final float EPSILON = 1e-4f;
    /** Well inside a frame, well outside float noise. */
    private static final float HAIR = 0.005f;

    /** A bare-handed fight sounds at once, on its first blow. */
    @Test
    void aBareHandedFightSoundsOnItsFirstBlow() {
        assertEquals(0f, Beats.strike(), EPSILON);
    }

    /** A weapon kill sounds two frames in, as the slash appears. */
    @Test
    void aWeaponKillSoundsAsTheSlashCrosses() {
        assertEquals(2 * FRAME, Beats.slice(), EPSILON);
        assertFalse(WeaponKill.slashShowing(Beats.slice() - HAIR));
        assertTrue(WeaponKill.slashShowing(Beats.slice() + HAIR));
    }

    /** An equip sounds three frames in, as the weapon lands on the rail. */
    @Test
    void anEquipSoundsAsTheWeaponReachesTheRail() {
        assertEquals(3 * FRAME, Beats.equip(), EPSILON);
        assertFalse(CardFlight.landed(CardFlight.EQUIP, 0, Beats.equip() - HAIR));
        assertTrue(CardFlight.landed(CardFlight.EQUIP, 0, Beats.equip() + HAIR));
    }

    /** An avoid sounds at once, as the sweep sets off. */
    @Test
    void anAvoidSweepsFromTheStart() {
        assertEquals(0f, Beats.sweep(), EPSILON);
        assertTrue(CardFlight.started(CardFlight.AVOID, 0, Beats.sweep()));
    }

    /** A drink sounds five frames in, as the pour starts. */
    @Test
    void aDrinkSoundsAsItPours() {
        assertEquals(5 * FRAME, Beats.drink(), EPSILON);
        assertFalse(PotionDrink.pouring(Beats.drink() - HAIR));
        assertTrue(PotionDrink.pouring(Beats.drink() + HAIR));
    }

    /** A spill sounds three frames in, as the potion starts to spill. */
    @Test
    void aSpillSoundsAsItSpills() {
        assertEquals(3 * FRAME, Beats.spill(), EPSILON);
        assertFalse(PotionSpill.spilling(Beats.spill() - HAIR));
        assertTrue(PotionSpill.spilling(Beats.spill() + HAIR));
    }

    /**
     * Each card of a deal sounds as it lands, the first three frames in and each
     * a frame after the one before.
     */
    @Test
    void eachCardOfADealSoundsAsItLandsAFrameAfterTheLast() {
        CardFlight.Flight deal = CardFlight.dealTo(0, 0);
        for (int slot = 0; slot < 4; slot++) {
            assertEquals((slot + 3) * FRAME, Beats.dealLanding(slot), EPSILON, "slot " + slot);
            assertFalse(CardFlight.landed(deal, slot, Beats.dealLanding(slot) - HAIR), "slot " + slot);
            assertTrue(CardFlight.landed(deal, slot, Beats.dealLanding(slot) + HAIR), "slot " + slot);
        }
    }

    /** Every beat falls inside its effect. */
    @Test
    void everyBeatFallsInsideItsEffect() {
        // A beat past the end would only ever play when the effect was flushed.
        assertTrue(Beats.strike() < Barehanded.TOTAL);
        assertTrue(Beats.slice() < WeaponKill.TOTAL);
        assertTrue(Beats.equip() <= CardFlight.EQUIP.total());
        assertTrue(Beats.sweep() < CardFlight.AVOID.total());
        assertTrue(Beats.drink() < PotionDrink.TOTAL);
        assertTrue(Beats.spill() < PotionSpill.TOTAL);
    }
}
