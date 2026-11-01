package com.tomer.scoundrel.audio;

import java.util.function.Consumer;

/**
 * The player's volume as it lives through a session: read once at launch,
 * saved the moment it changes, and never a crash.
 *
 * <p>{@link AudioSettingsStore} throws when the disk does, as every store does;
 * this is where that stops. A file that cannot be read means the defaults, and
 * a change that cannot be saved still holds until the game closes. Either is
 * handed to {@code onFailure} to be logged — sound is never worth a crash, and a
 * volume that will not stick is not worth a dialog.
 */
public final class AudioControls {

    private final AudioSettingsStore store;
    private final Consumer<RuntimeException> onFailure;
    private AudioSettings settings;
    private boolean minimised;

    /**
     * Loads the saved levels now, falling back to the defaults if they can't be read.
     *
     * @param store     where the levels are read from and saved to
     * @param onFailure told of any read or save that failed, for the log; must not throw
     */
    public AudioControls(AudioSettingsStore store, Consumer<RuntimeException> onFailure) {
        this.store = store;
        this.onFailure = onFailure;
        this.settings = read();
    }

    /**
     * The levels now.
     *
     * @return the current settings, including the mute
     */
    public AudioSettings settings() {
        return settings;
    }

    /**
     * The MUSIC plate: up a step, round to off, un-muting. Saved at once.
     *
     * @return the settings after the change
     */
    public AudioSettings cycleMusic() {
        return change(settings.cycleMusic());
    }

    /**
     * The SOUND plate, likewise.
     *
     * @return the settings after the change
     */
    public AudioSettings cycleSound() {
        return change(settings.cycleSound());
    }

    /**
     * M: silence everything, or bring it back at the levels it had. Saved at once.
     *
     * @return the settings after the change; {@link AudioSettings#muted()} says which way it went
     */
    public AudioSettings toggleMute() {
        return change(settings.toggleMute());
    }

    /**
     * The window went down or came back. Minimised, nothing is heard, but nothing
     * stops either: the audio keeps time with the picture, which goes on rendering,
     * so a cue due meanwhile plays out unheard rather than minutes late. Not a
     * setting, so nothing is saved.
     *
     * @param minimised true when the window has gone down, false when it is back
     */
    public void windowMinimised(boolean minimised) {
        this.minimised = minimised;
    }

    /**
     * The music's gain as it should sound now: the level, or silence while minimised.
     *
     * @return a linear amplitude from 0 (silent) to 1 (as mastered)
     */
    public float musicGain() {
        return minimised ? 0f : settings.musicGain();
    }

    /**
     * The sound effects' gain as they should sound now, likewise.
     *
     * @return a linear amplitude from 0 (silent) to 1 (as mastered)
     */
    public float soundGain() {
        return minimised ? 0f : settings.soundGain();
    }

    private AudioSettings read() {
        try {
            return store.load();
        } catch (RuntimeException e) {
            onFailure.accept(e);
            return AudioSettings.DEFAULTS;
        }
    }

    private AudioSettings change(AudioSettings next) {
        settings = next;
        try {
            store.save(next);
        } catch (RuntimeException e) {
            onFailure.accept(e);
        }
        return next;
    }
}
