package dev.luchoc.littlespaceship.core.domain.rng;

/**
 * Seeded pseudo-random generator for the simulation.
 *
 * <p>The core never falls back on the randomness the platform hands out: not {@code Math.random()},
 * not {@code java.util.Random}. A replay is a seed plus a sequence of input frames, so the generated
 * sequence has to be reproducible everywhere the game runs, and that includes the browser, where the
 * code goes through TeaVM.
 *
 * <p>The algorithm is Marsaglia's 32-bit xorshift, written with nothing but {@code ^}, {@code <<}
 * and {@code >>>} on {@code int}. Those three operations have exactly the same semantics on the JVM
 * and in JavaScript, so the stream cannot drift between desktop and web. Integer multiplication is
 * avoided on purpose: JavaScript numbers are doubles and a 32-bit product overflows their exact
 * range, which makes the result depend on how the transpiler emulates the operation.
 *
 * <p>The pinned contract is the integer stream produced by {@link #nextInt()}. Everything else is
 * derived from it. {@code RngTest} fixes a known sequence for a known seed, so changing the
 * algorithm fails loudly instead of silently invalidating every recorded replay.
 *
 * <p>Not thread-safe, which is not a limitation: the simulation is single-threaded by design.
 */
public final class Rng {

    /**
     * Any non-zero constant works as the fallback state. This one is the value used by Marsaglia's
     * reference implementation.
     */
    private static final int NON_ZERO_STATE = 0x1F123BB5;

    /** Fractional part of the golden ratio, the usual bit-mixing constant. */
    private static final int GOLDEN_RATIO = 0x9E3779B9;

    /** 1 / 2^24. Exact in binary floating point, so the conversion to float cannot round. */
    private static final float FLOAT_UNIT = 1.0f / (1 << 24);

    private final int seed;

    private int state;

    /**
     * Creates a generator for the given seed. Every seed is valid, zero included.
     *
     * @param seed the value identifying this sequence; the same seed always yields the same stream
     */
    public Rng(int seed) {
        this.seed = seed;
        this.state = scramble(seed);
    }

    /**
     * Returns the seed this generator was created with, so a replay can record it.
     *
     * @return the original seed
     */
    public int seed() {
        return seed;
    }

    /**
     * Advances the generator and returns the raw 32-bit value, negatives included.
     *
     * @return the next value in the stream
     */
    public int nextInt() {
        int x = state;
        x ^= x << 13;
        x ^= x >>> 17;
        x ^= x << 5;
        state = x;
        return x;
    }

    /**
     * Returns a value in {@code [0, bound)} with a uniform distribution.
     *
     * <p>The rejection loop is what removes the bias of a plain modulo: without it, the lowest
     * values of the range would come up slightly more often whenever the bound is not a power of
     * two. It terminates with probability one and consumes a variable number of values from the
     * stream, which is still deterministic because it depends only on the stream itself.
     *
     * @param bound the exclusive upper bound, strictly positive
     * @return a value in {@code [0, bound)}
     * @throws IllegalArgumentException if {@code bound} is not positive
     */
    public int nextInt(int bound) {
        if (bound <= 0) {
            throw new IllegalArgumentException("bound must be positive, was " + bound);
        }
        int value;
        int result;
        do {
            value = nextInt() >>> 1;
            result = value % bound;
        } while (value - result + (bound - 1) < 0);
        return result;
    }

    /**
     * Returns a value in {@code [0, 1)}.
     *
     * <p>Built from the 24 top bits and multiplied by an exact power of two, so the result is
     * representable in a float with no rounding. That keeps the value identical on any runtime,
     * which a generic division would not guarantee.
     *
     * @return a value in {@code [0, 1)}
     */
    public float nextFloat() {
        return (nextInt() >>> 8) * FLOAT_UNIT;
    }

    /**
     * Returns a boolean drawn from the sign bit, which is the best distributed one in a xorshift.
     *
     * @return the next boolean in the stream
     */
    public boolean nextBoolean() {
        return nextInt() < 0;
    }

    /**
     * Mixes the seed so that consecutive seeds produce unrelated sequences and so that no seed maps
     * to the zero state, the one fixed point a xorshift cannot leave.
     */
    private static int scramble(int seed) {
        int x = seed ^ GOLDEN_RATIO;
        x ^= x << 13;
        x ^= x >>> 17;
        x ^= x << 5;
        x ^= x << 13;
        x ^= x >>> 17;
        x ^= x << 5;
        return x == 0 ? NON_ZERO_STATE : x;
    }
}
