package dev.luchoc.littlespaceship.game;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;

/**
 * The options the flow's Options screen exposes, per {@code docs/planning/02-mvp-functional-spec.md}
 * — master, music and effects volume, and whether mouse control is enabled. Held on {@link
 * LittleSpaceshipGame} so it survives navigating away from the Options screen and back, the same way
 * a real settings store would.
 *
 * <p><b>The three volumes persist between sessions</b> — phase 08's acceptance criterion — through
 * libGDX's {@link Preferences}, which resolves to a small file on desktop and to {@code
 * localStorage} under TeaVM with the same API on both, so no backend-specific code lives here.
 * {@link #mouseEnabled} does not persist: nothing in the plan asked for it to, and adding it without
 * a stated need would be exactly the abstraction {@code CLAUDE.md}'s invariant 6 rules out.
 *
 * <p>Mutable and not a record on purpose: a slider's drag listener updates one field at a time, and
 * options changing independently of each other is the whole point of three separate sliders.
 */
public final class GameSettings {

    private static final String PREFS_NAME = "little-spaceship-settings";
    private static final String KEY_MASTER = "masterVolume";
    private static final String KEY_MUSIC = "musicVolume";
    private static final String KEY_EFFECTS = "effectsVolume";

    private float masterVolume = 0.8f;
    private float musicVolume = 0.6f;
    private float effectsVolume = 0.9f;
    private boolean mouseEnabled = true;

    /** Reads any previously saved volumes, leaving the defaults above for a first run. Call once,
     * before any screen reads a slider's initial value. */
    public void load() {
        Preferences prefs = Gdx.app.getPreferences(PREFS_NAME);
        masterVolume = prefs.getFloat(KEY_MASTER, masterVolume);
        musicVolume = prefs.getFloat(KEY_MUSIC, musicVolume);
        effectsVolume = prefs.getFloat(KEY_EFFECTS, effectsVolume);
    }

    private void save() {
        Preferences prefs = Gdx.app.getPreferences(PREFS_NAME);
        prefs.putFloat(KEY_MASTER, masterVolume);
        prefs.putFloat(KEY_MUSIC, musicVolume);
        prefs.putFloat(KEY_EFFECTS, effectsVolume);
        prefs.flush();
    }

    public float masterVolume() {
        return masterVolume;
    }

    public void masterVolume(float value) {
        masterVolume = value;
        save();
    }

    public float musicVolume() {
        return musicVolume;
    }

    public void musicVolume(float value) {
        musicVolume = value;
        save();
    }

    public float effectsVolume() {
        return effectsVolume;
    }

    public void effectsVolume(float value) {
        effectsVolume = value;
        save();
    }

    public boolean mouseEnabled() {
        return mouseEnabled;
    }

    public void mouseEnabled(boolean value) {
        mouseEnabled = value;
    }
}
