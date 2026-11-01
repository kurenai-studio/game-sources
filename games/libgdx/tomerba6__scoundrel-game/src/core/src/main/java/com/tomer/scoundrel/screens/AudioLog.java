package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.LaunchSwitch;

import java.util.Locale;
import java.util.function.Consumer;
import java.util.function.LongSupplier;

/**
 * The sound log: every sound played, every effect started, every skip, each with
 * the seconds since the game started. Off unless asked for.
 *
 * <p>This is how the audio is verified in the running game. Claude cannot hear
 * it, and a screenshot has no sound — but a log can show that each action
 * sounded exactly once, in order, on its beat. Turned on by
 * {@code SCOUNDREL_AUDIO_LOG=1} in the environment ({@code gradlew lwjgl3:run}
 * does not forward {@code -D} to the game's JVM, but the environment reaches
 * it), or {@code -Dscoundrel.audio.log=true} for a jar run directly.
 *
 * <p>Pure: the clock and the output are handed in, so it is tested headlessly.
 */
final class AudioLog {

    private final boolean enabled;
    private final LongSupplier nanos;
    private final Consumer<String> sink;
    private final long start;

    /**
     * A log whose clock starts now.
     *
     * @param enabled whether anything is written at all
     * @param nanos   the clock, in nanoseconds, like {@link System#nanoTime()}
     * @param sink    where each finished line goes
     */
    AudioLog(boolean enabled, LongSupplier nanos, Consumer<String> sink) {
        this.enabled = enabled;
        this.nanos = nanos;
        this.sink = sink;
        this.start = nanos.getAsLong();
    }

    /**
     * The log as this process was launched: on if {@link LaunchSwitch#AUDIO_LOG} is, to standard out.
     *
     * @return a log on the system clock, writing to {@link System#out}
     */
    static AudioLog fromLaunch() {
        return new AudioLog(LaunchSwitch.AUDIO_LOG.isOn(), System::nanoTime, System.out::println);
    }

    /**
     * Whether the log is on, so a caller can skip building a line nobody will read.
     *
     * @return true if lines are written
     */
    boolean enabled() {
        return enabled;
    }

    /**
     * Writes one line, {@code audio <seconds> <event>}, when the log is on.
     *
     * @param event what happened, e.g. the sound's file name
     */
    void log(String event) {
        if (enabled) {
            double seconds = (nanos.getAsLong() - start) / 1e9;
            sink.accept(String.format(Locale.ROOT, "audio %9.3f %s", seconds, event));
        }
    }
}
