package com.tomer.scoundrel.audio;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The volume controls: settings loaded at launch, changes saved at once, and silence while minimised. */
class AudioControlsTest {

    /** A fresh directory for each test, deleted afterwards. */
    @TempDir
    Path dir;

    private final List<RuntimeException> failures = new ArrayList<>();

    private AudioSettingsStore store() {
        return new AudioSettingsStore(dir.resolve("audio.settings"));
    }

    private AudioControls controls() {
        return new AudioControls(store(), failures::add);
    }

    /** With no settings file the controls start at the defaults, and that is not reported as a failure. */
    @Test
    void theFirstLaunchStartsAtTheDefaults() {
        assertEquals(AudioSettings.DEFAULTS, controls().settings());
        assertTrue(failures.isEmpty(), "no file yet is not a failure");
    }

    /** The controls start at the settings the last launch saved. */
    @Test
    void itStartsWhereTheLastLaunchLeftOff() {
        store().save(new AudioSettings(0, 1, true));
        assertEquals(new AudioSettings(0, 1, true), controls().settings());
    }

    /** A settings file that cannot be read gives the defaults, and the failure is reported once. */
    @Test
    void aSettingsFileThatCannotBeReadMeansTheDefaultsAndIsReported() throws IOException {
        Files.createDirectory(dir.resolve("audio.settings")); // exists, but is no file to read

        assertEquals(AudioSettings.DEFAULTS, controls().settings());
        assertEquals(1, failures.size());
    }

    /** Cycling the music level saves the change at once. */
    @Test
    void cyclingTheMusicSavesItAtOnce() {
        AudioControls controls = controls();

        AudioSettings changed = controls.cycleMusic();

        assertEquals(new AudioSettings(3, 3, false), changed);
        assertEquals(changed, controls.settings());
        assertEquals(changed, store().load());
    }

    /** Cycling the sound level saves the change at once. */
    @Test
    void cyclingTheSoundSavesItAtOnce() {
        AudioControls controls = controls();

        AudioSettings changed = controls.cycleSound();

        assertEquals(new AudioSettings(2, 0, false), changed);
        assertEquals(changed, controls.settings());
        assertEquals(changed, store().load());
    }

    /** Muting is saved at once, and unmuting restores the levels. */
    @Test
    void mutingSavesItAtOnceAndUnmutingBringsTheLevelsBack() {
        AudioControls controls = controls();

        assertEquals(new AudioSettings(2, 3, true), controls.toggleMute());
        assertEquals(new AudioSettings(2, 3, true), store().load());
        assertEquals(AudioSettings.DEFAULTS, controls.toggleMute());
        assertEquals(AudioSettings.DEFAULTS, store().load());
    }

    /** Changing a level while muted unmutes. */
    @Test
    void turningALevelWhileMutedUnmutes() {
        AudioControls controls = controls();
        controls.toggleMute();

        assertEquals(new AudioSettings(3, 3, false), controls.cycleMusic());
    }

    /** The gains it reports are those of the current levels. */
    @Test
    void shownTheGainsAreTheLevels() {
        AudioControls controls = controls();

        assertEquals(AudioSettings.DEFAULTS.musicGain(), controls.musicGain());
        assertEquals(AudioSettings.DEFAULTS.soundGain(), controls.soundGain());
    }

    /**
     * Minimised, nothing is heard - but the audio keeps time with the picture, so
     * this only silences: the levels stay as they are and nothing is saved.
     */
    @Test
    void minimisingSilencesEverythingWithoutTouchingTheLevels() {
        AudioControls controls = controls();

        controls.windowMinimised(true);

        assertEquals(0f, controls.musicGain());
        assertEquals(0f, controls.soundGain());
        assertEquals(AudioSettings.DEFAULTS, controls.settings());
        assertFalse(Files.exists(dir.resolve("audio.settings")), "a window state is not a setting");
    }

    /** Restoring the window brings the levels' gains back. */
    @Test
    void restoringTheWindowBringsTheLevelsBack() {
        AudioControls controls = controls();
        controls.windowMinimised(true);

        controls.windowMinimised(false);

        assertEquals(AudioSettings.DEFAULTS.musicGain(), controls.musicGain());
        assertEquals(AudioSettings.DEFAULTS.soundGain(), controls.soundGain());
    }

    /** A muted game stays silent when the window is restored. */
    @Test
    void mutedStaysSilentWhenTheWindowComesBack() {
        AudioControls controls = controls();
        controls.toggleMute();
        controls.windowMinimised(true);

        controls.windowMinimised(false);

        assertEquals(0f, controls.musicGain());
        assertEquals(0f, controls.soundGain());
    }

    /** A change whose save fails still holds for this session, and the failure is reported. */
    @Test
    void aSaveThatFailsKeepsTheChangeForThisSessionAndIsReported() throws IOException {
        AudioControls controls = controls();
        Files.createDirectory(dir.resolve("audio.settings")); // now nothing can be written there

        AudioSettings changed = controls.cycleSound();

        assertEquals(new AudioSettings(2, 0, false), changed);
        assertEquals(changed, controls.settings());
        assertEquals(1, failures.size());
    }
}
