package com.tomer.scoundrel;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The developer switches: which values turn one on, and the names they go by. */
class LaunchSwitchTest {

    /**
     * Either spelling turns a switch on. The environment variable is the one that
     * works through {@code gradlew lwjgl3:run}, which does not pass {@code -D} on.
     */
    @Test
    void eitherThePropertyOrTheEnvironmentTurnsItOn() {
        assertTrue(LaunchSwitch.on("true", null));
        assertTrue(LaunchSwitch.on(null, "1"));
        assertTrue(LaunchSwitch.on(null, "true"));
        assertTrue(LaunchSwitch.on("TRUE", "0"));
    }

    /** Unset, {@code false}, {@code 0} or any other value leaves a switch off. */
    @Test
    void anythingElseLeavesItOff() {
        assertFalse(LaunchSwitch.on(null, null));
        assertFalse(LaunchSwitch.on("false", "0"));
        assertFalse(LaunchSwitch.on("yes please", ""));
    }

    /** The names are what the docs and the run-scoundrel skill tell people to set. */
    @Test
    void theSwitchesAreNamedAsDocumented() {
        assertEquals(new LaunchSwitch("scoundrel.audio.log", "SCOUNDREL_AUDIO_LOG"), LaunchSwitch.AUDIO_LOG);
        assertEquals(new LaunchSwitch("scoundrel.no.audio", "SCOUNDREL_NO_AUDIO"), LaunchSwitch.NO_AUDIO);
    }
}
