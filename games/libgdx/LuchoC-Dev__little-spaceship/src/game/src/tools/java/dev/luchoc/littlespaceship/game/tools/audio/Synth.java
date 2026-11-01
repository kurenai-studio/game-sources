package dev.luchoc.littlespaceship.game.tools.audio;

/**
 * Building blocks for the sounds {@link GenerateAudio} composes: oscillators, noise, a one-pole
 * filter and additive mixing, all operating on plain {@code float[]} buffers at {@link
 * Wav#sampleRate()}. Nothing here is a general-purpose synth — every method is exactly what one of
 * the sounds in {@link GenerateAudio} needed, added when it needed it.
 *
 * <p>Noise uses a fixed-seed xorshift generator, not {@link java.util.Random}, for the same reason
 * {@code docs/design/fx/build-explosions.py} gives for the explosion strips it generates: the same
 * seed has to produce the same bytes every run, so a diff in a committed WAV means the recipe
 * actually changed.
 */
final class Synth {

    private static final int SR = Wav.sampleRate();

    private Synth() {
    }

    static int samples(float seconds) {
        return Math.round(seconds * SR);
    }

    /** A sine wave whose frequency sweeps linearly from {@code startHz} to {@code endHz}. */
    static float[] sweep(float startHz, float endHz, float seconds, Wave shape) {
        int n = samples(seconds);
        float[] out = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++) {
            float t = (float) i / n;
            float hz = startHz + (endHz - startHz) * t;
            phase += 2 * Math.PI * hz / SR;
            out[i] = shape.at(phase);
        }
        return out;
    }

    static float[] tone(float hz, float seconds, Wave shape) {
        return sweep(hz, hz, seconds, shape);
    }

    /** Deterministic white noise, xorshift32 seeded, matching every other generated frame's need
     * for a diff to mean an actual change rather than a re-roll. */
    static float[] noise(float seconds, int seed) {
        int n = samples(seconds);
        float[] out = new float[n];
        int state = seed == 0 ? 1 : seed;
        for (int i = 0; i < n; i++) {
            state ^= state << 13;
            state ^= state >>> 17;
            state ^= state << 5;
            out[i] = (state / (float) Integer.MAX_VALUE);
        }
        return out;
    }

    /** One-pole low-pass, {@code cutoff} in {@code (0, 1]} — closer to 0 is darker. */
    static float[] lowpass(float[] samples, float cutoff) {
        float[] out = new float[samples.length];
        float prev = 0f;
        for (int i = 0; i < samples.length; i++) {
            prev += cutoff * (samples[i] - prev);
            out[i] = prev;
        }
        return out;
    }

    /** Same filter with the cutoff sweeping from {@code startCutoff} down to {@code endCutoff}. */
    static float[] lowpassSweep(float[] samples, float startCutoff, float endCutoff) {
        float[] out = new float[samples.length];
        float prev = 0f;
        for (int i = 0; i < samples.length; i++) {
            float t = (float) i / samples.length;
            float cutoff = startCutoff + (endCutoff - startCutoff) * t;
            prev += cutoff * (samples[i] - prev);
            out[i] = prev;
        }
        return out;
    }

    /** Linear attack to 1, then linear decay to 0 — enough shape for a short percussive cue. */
    static float[] envelope(float[] samples, float attackFraction) {
        float[] out = new float[samples.length];
        int attackSamples = Math.max(1, Math.round(samples.length * attackFraction));
        for (int i = 0; i < samples.length; i++) {
            float gain;
            if (i < attackSamples) {
                gain = (float) i / attackSamples;
            } else {
                gain = 1f - (float) (i - attackSamples) / (samples.length - attackSamples);
            }
            out[i] = samples[i] * gain;
        }
        return out;
    }

    /** Exponential decay from 1 to ~0, the shape a plucked or struck sound actually has. */
    static float[] decay(float[] samples, float rate) {
        float[] out = new float[samples.length];
        for (int i = 0; i < samples.length; i++) {
            float t = (float) i / SR;
            out[i] = samples[i] * (float) Math.exp(-rate * t);
        }
        return out;
    }

    static float[] gain(float[] samples, float amount) {
        float[] out = new float[samples.length];
        for (int i = 0; i < samples.length; i++) {
            out[i] = samples[i] * amount;
        }
        return out;
    }

    /** Sums buffers of possibly different lengths, extending the result to the longest one. */
    static float[] mix(float[]... layers) {
        int length = 0;
        for (float[] layer : layers) {
            length = Math.max(length, layer.length);
        }
        float[] out = new float[length];
        for (float[] layer : layers) {
            for (int i = 0; i < layer.length; i++) {
                out[i] += layer[i];
            }
        }
        return out;
    }

    /** Places {@code clip} starting at {@code offsetSeconds} inside a buffer {@code totalSeconds} long. */
    static float[] place(float[] clip, float offsetSeconds, float totalSeconds) {
        float[] out = new float[samples(totalSeconds)];
        int offset = samples(offsetSeconds);
        for (int i = 0; i < clip.length && offset + i < out.length; i++) {
            out[offset + i] += clip[i];
        }
        return out;
    }

    /** Scales every sample so the loudest one hits {@code peak}, silence left untouched. */
    static float[] normalize(float[] samples, float peak) {
        float max = 0f;
        for (float sample : samples) {
            max = Math.max(max, Math.abs(sample));
        }
        if (max < 1e-6f) {
            return samples;
        }
        return gain(samples, peak / max);
    }

    /** A waveform shape sampled from a running phase, in radians. */
    interface Wave {
        float at(double phase);

        Wave SINE = phase -> (float) Math.sin(phase);
        Wave SQUARE = phase -> Math.sin(phase) >= 0 ? 1f : -1f;
        Wave TRIANGLE = phase -> {
            double normalized = (phase / (2 * Math.PI)) % 1.0;
            if (normalized < 0) {
                normalized += 1.0;
            }
            return (float) (4 * Math.abs(normalized - 0.5) - 1);
        };
    }
}
