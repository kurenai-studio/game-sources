package dev.luchoc.littlespaceship.rngparity;

import dev.luchoc.littlespaceship.core.domain.rng.Rng;

/**
 * Runs the real {@code core} {@link Rng} — not a copy — and checks that it reproduces the pinned
 * sequences {@code RngTest} asserts on the JVM. This class is compiled twice by the Gradle task
 * that owns this module: once for the JVM ({@code runOnJvm}) and once through TeaVM to JavaScript,
 * then run on Node ({@code runOnNode}). Both runs execute this exact code, so a divergence between
 * runtimes fails whichever run computes a different value from the one pinned here — there is
 * nothing that compares the two runs against each other, because comparing both against the same
 * fixed expectation is the stronger check and needs no extra plumbing to move values between them.
 *
 * <p>The three expected sequences below are copied verbatim from {@code RngTest} (the integer
 * stream for seed 12345, the integer stream for seed 0, and the float stream for seed 12345) rather
 * than recomputed, so this check does not assert a second, independently derived set of
 * expectations. They were verified identical on 27/08/2026, and <b>nothing enforces that they stay
 * so</b> — which is the same complaint {@code #52} made about the copied {@code Rng.java} this
 * module replaced, with a different noun. Tracked as
 * <a href="https://github.com/LuchoC-Dev/little-spaceship/issues/108">#108</a>: the fix is to stop
 * duplicating them, by having the JVM run produce what the Node run is compared against.
 */
public final class Main {

    private static final int[] EXPECTED_INTS_SEED_12345 = {
        -598146918, 1963845983, -856963892, 976339029,
        1163348040, 664654471, 610463809, 926368756
    };

    private static final int[] EXPECTED_INTS_SEED_0 = {
        2075758394, 25405621, -432837345, -108408265,
        -1171969584, -50598465, -1463423431, -1252371528
    };

    private static final float[] EXPECTED_FLOATS_SEED_12345 = {
        0.86073303f, 0.4572435f, 0.8004725f,
        0.22732162f, 0.27086306f, 0.1547519f
    };

    public static void main(String[] args) {
        boolean ok = true;
        ok &= checkInts("ints[seed=12345]", EXPECTED_INTS_SEED_12345, new Rng(12345));
        ok &= checkInts("ints[seed=0]", EXPECTED_INTS_SEED_0, new Rng(0));
        ok &= checkFloats("floats[seed=12345]", EXPECTED_FLOATS_SEED_12345, new Rng(12345));

        if (!ok) {
            throw new IllegalStateException(
                "Rng parity check failed on this runtime — see the mismatches printed above.");
        }
        System.out.println("Rng parity check: all three pinned sequences match on this runtime.");
    }

    private static boolean checkInts(String label, int[] expected, Rng rng) {
        boolean ok = true;
        StringBuilder actual = new StringBuilder();
        for (int i = 0; i < expected.length; i++) {
            int value = rng.nextInt();
            if (i > 0) {
                actual.append(", ");
            }
            actual.append(value);
            if (value != expected[i]) {
                ok = false;
            }
        }
        System.out.println((ok ? "OK   " : "FAIL ") + label + ": " + actual);
        return ok;
    }

    private static boolean checkFloats(String label, float[] expected, Rng rng) {
        boolean ok = true;
        StringBuilder actual = new StringBuilder();
        for (int i = 0; i < expected.length; i++) {
            float value = rng.nextFloat();
            if (i > 0) {
                actual.append(", ");
            }
            actual.append(value);
            if (value != expected[i]) {
                ok = false;
            }
        }
        System.out.println((ok ? "OK   " : "FAIL ") + label + ": " + actual);
        return ok;
    }

    private Main() {
    }
}
