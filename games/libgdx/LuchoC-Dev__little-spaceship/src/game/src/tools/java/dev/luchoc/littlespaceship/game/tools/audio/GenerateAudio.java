package dev.luchoc.littlespaceship.game.tools.audio;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * Writes every WAV file {@code game}'s audio system plays, procedurally: bleeps and sweeps for
 * shots and UI, filtered noise for explosions and impacts, arpeggios and a bass line for music.
 *
 * <p><b>Why synthesised instead of sourced</b> — recorded in {@code
 * docs/plan/08-audio-and-polish/status.md}: no licence to audit, no dependency the web target
 * would inherit, and it is how games at this resolution actually did it.
 *
 * <p><b>Why a design-time tool with committed output</b>, and not a build step: the same reasoning
 * {@code docs/design/mockups/README.md} gives for {@code build.py} and {@code
 * docs/design/fx/build-explosions.py} give for the explosion strips — deterministic generation from
 * a fixed seed, run by hand when a sound actually changes, with the output committed like any other
 * asset. A Gradle task wired into every build would re-run this on every clean checkout for files
 * that change only when this class does; {@code ./gradlew :game:generateAudio} exists for
 * convenience but is never part of {@code build} or {@code test}.
 *
 * <p>Run it with {@code ./gradlew :game:generateAudio}, or directly as {@code java
 * dev.luchoc.littlespaceship.game.tools.audio.GenerateAudio <output-dir>} — {@code
 * assets/audio} at the repository root is what {@code game} actually loads from.
 */
public final class GenerateAudio {

    private GenerateAudio() {
    }

    public static void main(String[] args) throws IOException {
        Path outputRoot = Path.of(args.length > 0 ? args[0] : "assets/audio");
        Path sfx = outputRoot.resolve("sfx");
        Path music = outputRoot.resolve("music");

        Wav.write(sfx.resolve("shoot.wav"), shoot());
        Wav.write(sfx.resolve("impact.wav"), impact());
        Wav.write(sfx.resolve("explosion.wav"), explosion());
        Wav.write(sfx.resolve("powerup.wav"), powerup());
        Wav.write(sfx.resolve("bomb.wav"), bomb());
        Wav.write(sfx.resolve("ui-select.wav"), uiSelect());

        Wav.write(music.resolve("level.wav"), levelMusic());
        Wav.write(music.resolve("boss.wav"), bossMusic());

        System.out.println("Wrote 6 effects and 2 music loops under " + outputRoot.toAbsolutePath());
    }

    // --- Effects -------------------------------------------------------------------------------

    /** A quick upward blip, the ship's own shot. */
    private static float[] shoot() {
        float[] tone = Synth.sweep(700f, 1100f, 0.07f, Synth.Wave.SQUARE);
        return Synth.normalize(Synth.decay(tone, 28f), 0.5f);
    }

    /** A short noisy thud plus a low thump — the player absorbing a hit. */
    private static float[] impact() {
        float[] burst = Synth.lowpassSweep(Synth.noise(0.09f, 7), 0.6f, 0.08f);
        float[] thump = Synth.tone(110f, 0.09f, Synth.Wave.SINE);
        float[] mixed = Synth.mix(Synth.decay(burst, 30f), Synth.decay(thump, 24f));
        return Synth.normalize(mixed, 0.6f);
    }

    /** Filtered noise opening bright and closing dark, under a falling sub-bass sweep. */
    private static float[] explosion() {
        float[] noiseLayer = Synth.lowpassSweep(Synth.noise(0.4f, 11), 0.9f, 0.03f);
        float[] subLayer = Synth.sweep(150f, 40f, 0.35f, Synth.Wave.SINE);
        float[] mixed = Synth.mix(
            Synth.decay(noiseLayer, 6f),
            Synth.decay(Synth.gain(subLayer, 0.8f), 5f));
        return Synth.normalize(mixed, 0.85f);
    }

    /** A rising major-triad arpeggio, the power-up chime. */
    private static float[] powerup() {
        float[] a = Synth.place(Synth.decay(Synth.tone(523.25f, 0.09f, Synth.Wave.SQUARE), 16f), 0.00f, 0.30f);
        float[] b = Synth.place(Synth.decay(Synth.tone(659.25f, 0.09f, Synth.Wave.SQUARE), 16f), 0.07f, 0.30f);
        float[] c = Synth.place(Synth.decay(Synth.tone(784.00f, 0.14f, Synth.Wave.SQUARE), 12f), 0.14f, 0.30f);
        return Synth.normalize(Synth.mix(a, b, c), 0.55f);
    }

    /** The explosion's bigger, deeper sibling — a heavier hit for the one-shot bomb. */
    private static float[] bomb() {
        float[] noiseLayer = Synth.lowpassSweep(Synth.noise(0.6f, 23), 1f, 0.02f);
        float[] subLayer = Synth.sweep(200f, 30f, 0.55f, Synth.Wave.SINE);
        float[] mixed = Synth.mix(
            Synth.decay(noiseLayer, 4f),
            Synth.decay(Synth.gain(subLayer, 1f), 3.5f));
        return Synth.normalize(mixed, 0.95f);
    }

    /** A single short blip for menu navigation and confirmation alike. */
    private static float[] uiSelect() {
        float[] tone = Synth.tone(1200f, 0.03f, Synth.Wave.SQUARE);
        return Synth.normalize(Synth.decay(tone, 60f), 0.35f);
    }

    // --- Music -----------------------------------------------------------------------------------

    /**
     * A four-bar loop in A minor at a moderate tempo: a triangle bass walking the root and fifth,
     * a square arpeggio riding over it. The total length is exact bar math (4 beats/bar, {@code
     * secondsPerBeat}), which is what lets the runtime side loop it with {@code
     * Music.setLooping(true)} and no audible seam.
     */
    private static float[] levelMusic() {
        return arrangement(0.42f, 4, false);
    }

    /** The same arrangement, faster and with a higher, more urgent arpeggio register — the boss cue. */
    private static float[] bossMusic() {
        return arrangement(0.28f, 4, true);
    }

    private static float[] arrangement(float secondsPerBeat, int bars, boolean intense) {
        float barSeconds = secondsPerBeat * 4f;
        float totalSeconds = barSeconds * bars;
        List<float[]> layers = new ArrayList<>();

        // A minor: A, C, E, G as scale degrees for both bass and arpeggio.
        float[] bassNotes = {110f, 110f, 130.81f, 98f}; // A2, A2, C3, G2 — one per bar
        float[] arpNotes = intense
            ? new float[]{440f, 523.25f, 659.25f, 523.25f} // A4, C5, E5, C5
            : new float[]{220f, 261.63f, 329.63f, 261.63f}; // A3, C4, E4, C4

        for (int bar = 0; bar < bars; bar++) {
            float barStart = bar * barSeconds;
            float bassFreq = bassNotes[bar % bassNotes.length];
            float[] bassNote = Synth.decay(
                Synth.tone(bassFreq, barSeconds, Synth.Wave.TRIANGLE), 2.2f);
            layers.add(Synth.place(Synth.gain(bassNote, 0.5f), barStart, totalSeconds));

            // Four arpeggio steps per bar, one per beat, cycling through the bar's chord tones.
            for (int beat = 0; beat < 4; beat++) {
                float freq = arpNotes[beat % arpNotes.length];
                float[] pluck = Synth.decay(
                    Synth.tone(freq, secondsPerBeat, Synth.Wave.SQUARE), intense ? 9f : 12f);
                layers.add(Synth.place(Synth.gain(pluck, intense ? 0.3f : 0.24f),
                    barStart + beat * secondsPerBeat, totalSeconds));
            }
        }

        float[] mixed = Synth.mix(layers.toArray(new float[0][]));
        return Synth.normalize(mixed, 0.7f);
    }
}
