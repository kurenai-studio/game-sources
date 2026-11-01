package com.tomer.scoundrel.audio;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

/**
 * Chooses which version of a sound plays, never the same one twice in a row.
 *
 * <p>An identical recording repeated back to back stops reading as an event
 * and starts reading as a sample — the "machine-gun effect" — and this game
 * repeats: four flips a room, twenty-six kills a run. A plain random pick
 * would still hand out the same version twice a third of the time with three
 * of them, so the last pick of each sound is remembered and excluded.
 *
 * <p>Remembered per stem ({@code blade_light}, {@code flip}), because that is
 * what the ear compares: two different sounds sharing a version number is not
 * a repeat. Seeded, so a test can pin the sequence.
 */
final class VariantPicker {

    private final Random random;
    private final Map<String, Integer> last = new HashMap<>();

    /**
     * A picker with no history yet.
     *
     * @param random where the choices come from; seed it to pin the sequence in a test
     */
    VariantPicker(Random random) {
        this.random = random;
    }

    /**
     * A version of {@code stem}, counted from 1, that is not the one it played last.
     *
     * @param stem     the sound and weight the versions belong to, e.g. {@code blade_light}
     * @param versions how many versions the stem has, 1 or more
     * @return a version from 1 to {@code versions}; always 1 when there is only one
     * @throws IllegalArgumentException if {@code versions} is less than 1
     */
    int pick(String stem, int versions) {
        if (versions < 1) {
            throw new IllegalArgumentException(stem + " needs at least one version, got " + versions);
        }
        if (versions == 1) {
            return 1;
        }
        Integer previous = last.get(stem);
        int choice;
        if (previous == null) {
            choice = 1 + random.nextInt(versions);
        } else {
            // Draw from the others only, then step over the previous one, so
            // each of them stays equally likely.
            int drawn = 1 + random.nextInt(versions - 1);
            choice = drawn >= previous ? drawn + 1 : drawn;
        }
        last.put(stem, choice);
        return choice;
    }
}
