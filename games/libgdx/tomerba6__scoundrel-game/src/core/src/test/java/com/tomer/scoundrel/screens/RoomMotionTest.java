package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Which clock each card of the room is on while the board is moving. Resolving
 * a card sets three things going at once and they are not the same thing: what
 * happens to the card that left, the survivors re-centring around the gap, and
 * whatever the dungeon sends up to replace it.
 */
class RoomMotionTest {

    private static RoomMotion.Phase survivor(boolean effect, boolean closing, boolean dealing) {
        return RoomMotion.of(true, effect, closing, dealing);
    }

    private static RoomMotion.Phase fresh(boolean effect, boolean closing, boolean dealing) {
        return RoomMotion.of(false, effect, closing, dealing);
    }

    /** With nothing moving, every card rests. */
    @Test
    void aSettledRoomIsAtRest() {
        assertEquals(RoomMotion.Phase.RESTING, survivor(false, false, false));
        assertEquals(RoomMotion.Phase.RESTING, fresh(false, false, false));
    }

    /**
     * A survivor re-centres <em>while</em> the resolved card is still being
     * killed, drunk or carried away — the room closes over the gap rather than
     * waiting for the effect and then shuffling along after it.
     */
    @Test
    void theRoomClosesWhileTheEffectIsStillPlaying() {
        assertEquals(RoomMotion.Phase.SLIDING, survivor(true, true, false));
        assertEquals(RoomMotion.Phase.SLIDING, survivor(true, true, true));
    }

    /** A survivor slides while the room closes, whether or not a card is being dealt. */
    @Test
    void aSurvivorSlidesWhetherOrNotAnythingIsBeingDealt() {
        assertEquals(RoomMotion.Phase.SLIDING, survivor(false, true, false));
        assertEquals(RoomMotion.Phase.SLIDING, survivor(false, true, true));
    }

    /**
     * A replacement does not overlap the effect, though. It is still in the
     * dungeon, and drawing it early would fly a fresh card over the top of the
     * one being killed.
     */
    @Test
    void aReplacementStaysInTheDungeonUntilTheEffectIsOver() {
        assertEquals(RoomMotion.Phase.HIDDEN, fresh(true, false, false));
        assertEquals(RoomMotion.Phase.HIDDEN, fresh(true, true, true));
    }

    /** A replacement is dealt once the effect has finished. */
    @Test
    void aReplacementComesUpOnceTheEffectHasFinished() {
        assertEquals(RoomMotion.Phase.DEALING, fresh(false, false, true));
        assertEquals(RoomMotion.Phase.DEALING, fresh(false, true, true));
    }

    /** A survivor is never hidden — it is already on the table. */
    @Test
    void aSurvivorIsNeverHidden() {
        for (boolean effect : new boolean[] {false, true}) {
            for (boolean closing : new boolean[] {false, true}) {
                for (boolean dealing : new boolean[] {false, true}) {
                    assertEquals(closing ? RoomMotion.Phase.SLIDING : RoomMotion.Phase.RESTING,
                            survivor(effect, closing, dealing),
                            "effect=" + effect + " closing=" + closing + " dealing=" + dealing);
                }
            }
        }
    }
}
