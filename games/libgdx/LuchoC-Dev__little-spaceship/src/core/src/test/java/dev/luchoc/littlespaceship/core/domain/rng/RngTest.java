package dev.luchoc.littlespaceship.core.domain.rng;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class RngTest {

    /**
     * The sequences below are the contract, not an implementation detail. Every recorded replay
     * depends on them: changing the algorithm changes the outcome of every game that was ever
     * captured. If this test fails, either the change was deliberate and every replay has to be
     * regenerated, or something was broken by accident.
     *
     * <p>This test only proves the contract on the JVM. This one, {@link #zeroSeed()} and
     * {@link #pinnedFloatSequence()} are also asserted against the real {@link Rng} running under
     * TeaVM/JavaScript on Node by {@code ./gradlew :rngparity:rngParityCheck} — run it after
     * touching this algorithm. It is not part of the per-push CI job.
     */
    @Test
    @DisplayName("reproduces the pinned sequence for a pinned seed")
    void pinnedSequence() {
        int[] expected = {
            -598146918, 1963845983, -856963892, 976339029,
            1163348040, 664654471, 610463809, 926368756
        };

        assertArrayEquals(expected, draw(new Rng(12345), expected.length));
    }

    @Test
    @DisplayName("a zero seed produces a healthy sequence")
    void zeroSeed() {
        int[] expected = {
            2075758394, 25405621, -432837345, -108408265,
            -1171969584, -50598465, -1463423431, -1252371528
        };

        assertArrayEquals(expected, draw(new Rng(0), expected.length));
    }

    /**
     * A xorshift stuck at zero returns zero for ever. The seed is mixed with the golden ratio
     * constant, so the one seed that would cancel it out is this one; it must still produce a
     * usable stream.
     */
    @Test
    @DisplayName("the seed that cancels the mixing constant still produces a healthy sequence")
    void degenerateSeed() {
        int[] expected = {
            1425164135, -1614052248, 127437483, -814622611,
            2080131123, -1380943730, -157494754, -147084719
        };

        assertArrayEquals(expected, draw(new Rng(0x9E3779B9), expected.length));
    }

    @Test
    @DisplayName("pins the float sequence too, since positions are floats")
    void pinnedFloatSequence() {
        float[] expected = {
            0.86073303f, 0.4572435f, 0.8004725f,
            0.22732162f, 0.27086306f, 0.1547519f
        };

        Rng rng = new Rng(12345);
        for (int i = 0; i < expected.length; i++) {
            assertEquals(expected[i], rng.nextFloat(), 0f, "value " + i);
        }
    }

    @Test
    @DisplayName("the same seed produces the same stream")
    void sameSeedSameStream() {
        assertArrayEquals(draw(new Rng(777), 64), draw(new Rng(777), 64));
    }

    @Test
    @DisplayName("different seeds diverge from the first value")
    void differentSeedsDiverge() {
        assertNotEquals(new Rng(1).nextInt(), new Rng(2).nextInt());
    }

    @Test
    @DisplayName("keeps the seed so a replay can record it")
    void keepsSeed() {
        assertEquals(-42, new Rng(-42).seed());
    }

    @Test
    @DisplayName("nextFloat stays inside [0, 1)")
    void floatRange() {
        Rng rng = new Rng(3);
        for (int i = 0; i < 100_000; i++) {
            float value = rng.nextFloat();
            assertTrue(value >= 0f && value < 1f, "out of range: " + value);
        }
    }

    @Test
    @DisplayName("nextInt(bound) stays inside the range and covers it evenly")
    void boundedRange() {
        int bound = 6;
        int draws = 60_000;
        int[] counts = new int[bound];

        Rng rng = new Rng(2024);
        for (int i = 0; i < draws; i++) {
            counts[rng.nextInt(bound)]++;
        }

        int expected = draws / bound;
        for (int value = 0; value < bound; value++) {
            assertTrue(Math.abs(counts[value] - expected) < expected / 10,
                "value " + value + " came up " + counts[value] + " times");
        }
    }

    @Test
    @DisplayName("nextInt(bound) rejects a non-positive bound")
    void boundMustBePositive() {
        Rng rng = new Rng(1);

        assertThrows(IllegalArgumentException.class, () -> rng.nextInt(0));
        assertThrows(IllegalArgumentException.class, () -> rng.nextInt(-3));
    }

    @Test
    @DisplayName("nextBoolean is not stuck on one value")
    void booleansAreBalanced() {
        Rng rng = new Rng(99);
        int trues = 0;
        for (int i = 0; i < 10_000; i++) {
            if (rng.nextBoolean()) {
                trues++;
            }
        }

        assertTrue(trues > 4_500 && trues < 5_500, "unbalanced: " + trues + " out of 10000");
    }

    @Test
    @DisplayName("does not repeat itself in the span a level would consume")
    void noShortCycle() {
        Rng rng = new Rng(5);
        int first = rng.nextInt();
        boolean repeated = false;
        for (int i = 0; i < 100_000; i++) {
            repeated |= rng.nextInt() == first;
        }

        assertFalse(repeated, "the stream repeated inside 100000 values");
    }

    private static int[] draw(Rng rng, int count) {
        int[] values = new int[count];
        for (int i = 0; i < count; i++) {
            values[i] = rng.nextInt();
        }
        return values;
    }
}
