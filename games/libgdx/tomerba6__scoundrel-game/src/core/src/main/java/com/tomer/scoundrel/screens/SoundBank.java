package com.tomer.scoundrel.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.utils.Disposable;
import com.tomer.scoundrel.audio.AudioSettings;
import com.tomer.scoundrel.audio.Sfx;
import com.tomer.scoundrel.audio.SfxChoice;
import com.tomer.scoundrel.audio.Sound;

import java.util.ArrayDeque;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * The sound effects, loaded and played. Everything that decides <em>which</em>
 * sound is pure and lives in {@code audio}; this only plays what it is handed,
 * at the player's volume, and keeps each sound to its {@link Sound#voices()}.
 *
 * <p><b>It never takes the game down.</b> A file that fails to load is logged
 * once and then silent; a play that throws is caught. With no audio device at
 * all LibGDX hands back a silent mock and this runs on it unchanged. Sound is
 * never worth a crash.
 *
 * <p>Owned by {@code ScoundrelGame}, like the theme and the sprites, so every
 * screen plays through the one bank and the one {@link SfxChoice} — whose
 * memory of the last version played is what keeps repeats apart.
 */
public final class SoundBank implements Disposable {

    /**
     * One sound playing, as LibGDX identifies it, so the oldest can be stopped — and
     * its volume before the player's gain, so a level change reaches it mid-play.
     */
    private record Voice(com.badlogic.gdx.audio.Sound sound, long id, float base) {
    }

    private final Map<String, com.badlogic.gdx.audio.Sound> loaded = new HashMap<>();
    private final Map<Sound, ArrayDeque<Voice>> voices = new EnumMap<>(Sound.class);
    private final SfxChoice choice = new SfxChoice(System.nanoTime());
    private final AudioLog log = AudioLog.fromLaunch();
    private float gain = AudioSettings.DEFAULTS.soundGain();

    /**
     * Loads every sound-effect file {@link Sound#allFiles()} names. A file that
     * fails to load is logged and left out, so that sound is silent.
     *
     * @see com.badlogic.gdx.Audio#newSound(com.badlogic.gdx.files.FileHandle)
     */
    public SoundBank() {
        for (String name : Sound.allFiles()) {
            String path = Sfx.DIRECTORY + name + Sfx.EXTENSION;
            try {
                loaded.put(name, Gdx.audio.newSound(Gdx.files.internal(path)));
            } catch (RuntimeException e) {
                Gdx.app.error("audio", "could not load " + path + "; it will be silent", e);
            }
        }
        log.log("loaded " + loaded.size() + " of " + Sound.allFiles().size() + " sound effects on "
                + Gdx.audio.getClass().getSimpleName());
    }

    /**
     * What each moment sounds like. Shared, so versions do not repeat across screens.
     *
     * @return the one chooser, seeded at launch
     */
    public SfxChoice choice() {
        return choice;
    }

    /**
     * The sound-effect gain as it should sound now, 0..1: the player's level, or
     * silence while muted or minimised. Sounds already playing follow it, so a chime
     * that has just begun goes quiet with the window.
     *
     * @param gain the linear gain, 0 to 1
     */
    public void setGain(float gain) {
        this.gain = gain;
        for (ArrayDeque<Voice> playing : voices.values()) {
            for (Voice voice : playing) {
                try {
                    // Harmless if it has already finished on its own.
                    voice.sound().setVolume(voice.id(), gain * voice.base());
                } catch (RuntimeException e) {
                    Gdx.app.error("audio", "could not change a playing sound's volume", e);
                }
            }
        }
    }

    /**
     * Plays a sound now. Past its voice limit, the oldest copy stops first.
     * Nothing plays at zero gain or for a file that failed to load, but it is logged.
     *
     * @param sfx the chosen sound, with its pitch and volume
     */
    public void play(Sfx sfx) {
        float volume = gain * sfx.volume();
        com.badlogic.gdx.audio.Sound sound = loaded.get(sfx.file());
        log.log(String.format(Locale.ROOT, "play %s pitch=%.3f vol=%.3f%s", sfx.file(), sfx.pitch(), volume,
                sound == null ? " (not loaded)" : ""));
        if (sound == null || volume <= 0f) {
            return;
        }
        try {
            ArrayDeque<Voice> playing = voices.computeIfAbsent(sfx.sound(), s -> new ArrayDeque<>());
            while (playing.size() >= sfx.sound().voices()) {
                Voice oldest = playing.poll();
                // Harmless if it has already finished on its own.
                oldest.sound().stop(oldest.id());
            }
            long id = sound.play(volume, sfx.pitch(), 0f);
            if (id != -1) {
                playing.add(new Voice(sound, id, sfx.volume()));
            }
        } catch (RuntimeException e) {
            Gdx.app.error("audio", "could not play " + sfx.file(), e);
        }
    }

    /**
     * Plays each, now, in order.
     *
     * @param sounds the sounds, e.g. everything a skip flushed
     */
    public void playAll(Iterable<Sfx> sounds) {
        for (Sfx sfx : sounds) {
            play(sfx);
        }
    }

    /**
     * A line in the sound log, for the board's effects and skips and the music's milestones.
     *
     * @param event what happened
     */
    void log(String event) {
        log.log(event);
    }

    /**
     * Whether the sound log is on, so a caller can skip working out what it would say.
     *
     * @return true if log lines are written
     */
    boolean logging() {
        return log.enabled();
    }

    @Override
    public void dispose() {
        for (com.badlogic.gdx.audio.Sound sound : loaded.values()) {
            sound.dispose();
        }
        loaded.clear();
        voices.clear();
    }
}
