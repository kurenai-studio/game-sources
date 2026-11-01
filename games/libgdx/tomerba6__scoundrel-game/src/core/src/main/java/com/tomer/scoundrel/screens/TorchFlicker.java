package com.tomer.scoundrel.screens;

/**
 * A torch's restless light as a pure function of time: a brightness multiplier
 * around 1, layered from three incommensurate sines so the pattern never visibly
 * repeats. No LibGDX — the {@link Backdrop} multiplies its glow alpha by this,
 * and it is tested headlessly (a sibling of {@link Embers}).
 */
final class TorchFlicker {

    /** The multiplier stays within {@code [1 - DEPTH, 1 + DEPTH]}. */
    static final float DEPTH = 0.18f;

    private TorchFlicker() {
    }

    /**
     * The torch's brightness at a moment. Smooth and continuous by design — the
     * backdrop is the one place the quantised-timing rule does not apply.
     *
     * @param seconds time since the backdrop started, any value
     * @return a multiplier within {@code [1 - DEPTH, 1 + DEPTH]}
     */
    static float intensityAt(float seconds) {
        // Weights sum to 1 and each sine spans [-1, 1], so the blend spans [-1, 1];
        // the frequencies share no common period, so it does not loop.
        double blend = 0.50 * Math.sin(seconds * 11.0)
                + 0.35 * Math.sin(seconds * 6.3 + 1.7)
                + 0.15 * Math.sin(seconds * 2.9 + 4.2);
        return 1f + (float) blend * DEPTH;
    }
}
