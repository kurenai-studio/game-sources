package com.tomer.scoundrel.audio;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.Set;
import java.util.TreeSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Picking which version of a sound plays next. */
class VariantPickerTest {

    private static VariantPicker picker(long seed) {
        return new VariantPicker(new Random(seed));
    }

    /** A sound with one version always gets version 1. */
    @Test
    void aSoundWithOneVersionAlwaysGetsIt() {
        VariantPicker picker = picker(1);
        for (int i = 0; i < 20; i++) {
            assertEquals(1, picker.pick("click", 1));
        }
    }

    /** With two or three versions, the same version never plays twice in a row. */
    @Test
    void neverTheSameVersionTwiceInARow() {
        for (int versions = 2; versions <= 3; versions++) {
            VariantPicker picker = picker(versions);
            int previous = picker.pick("flip", versions);
            for (int i = 0; i < 1000; i++) {
                int next = picker.pick("flip", versions);
                assertNotEquals(previous, next, "pick " + i + " of " + versions + " versions");
                previous = next;
            }
        }
    }

    /** Versions are numbered from 1, and every one comes up. */
    @Test
    void everyVersionComesUpAndIsCountedFromOne() {
        VariantPicker picker = picker(7);
        Set<Integer> seen = new TreeSet<>();
        for (int i = 0; i < 300; i++) {
            int version = picker.pick("flip", 3);
            assertTrue(version >= 1 && version <= 3, "version " + version);
            seen.add(version);
        }
        assertEquals(Set.of(1, 2, 3), seen);
    }

    /** The no-repeat rule is kept per sound, even with two sounds interleaved. */
    @Test
    void eachSoundRemembersItsOwnLastVersion() {
        // Two sounds interleaved: the no-repeat rule is per sound, so with two
        // versions each one's own picks must still alternate strictly.
        VariantPicker picker = picker(3);
        List<Integer> blades = new ArrayList<>();
        for (int i = 0; i < 50; i++) {
            blades.add(picker.pick("blade_light", 2));
            picker.pick("fist_heavy", 2);
        }
        for (int i = 1; i < blades.size(); i++) {
            assertNotEquals(blades.get(i - 1), blades.get(i), "blade pick " + i);
        }
    }

    /** The same seed gives the same sequence. */
    @Test
    void theSameSeedGivesTheSameSequence() {
        VariantPicker a = picker(42);
        VariantPicker b = picker(42);
        for (int i = 0; i < 50; i++) {
            assertEquals(a.pick("flip", 3), b.pick("flip", 3), "pick " + i);
        }
    }

    /** Asking with no versions throws IllegalArgumentException. */
    @Test
    void aSoundNeedsAtLeastOneVersion() {
        assertThrows(IllegalArgumentException.class, () -> picker(1).pick("nothing", 0));
    }
}
