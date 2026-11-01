package com.tomer.scoundrel;

/**
 * A developer switch read at launch, spelled two ways: a system property, or an
 * environment variable — the one that works through {@code gradlew lwjgl3:run},
 * which does not pass {@code -D} on to the game's JVM. Pure, and in the root
 * package because the launcher reads one and the screens the other.
 *
 * @param property    the system property's name, on when it is {@code true} (any case)
 * @param environment the environment variable's name, on when it is {@code 1} or {@code true}
 */
public record LaunchSwitch(String property, String environment) {

    /** The sound log: every sound, cue and level change, timestamped, on standard out. */
    public static final LaunchSwitch AUDIO_LOG = new LaunchSwitch("scoundrel.audio.log", "SCOUNDREL_AUDIO_LOG");
    /** No audio device, simulated: the launcher starts LibGDX with its audio disabled. */
    public static final LaunchSwitch NO_AUDIO = new LaunchSwitch("scoundrel.no.audio", "SCOUNDREL_NO_AUDIO");

    /**
     * Whether this process was launched with the switch on.
     *
     * @return true if either spelling is set to an on value
     * @see System#getProperty(String)
     * @see System#getenv(String)
     */
    public boolean isOn() {
        return on(System.getProperty(property), System.getenv(environment));
    }

    /**
     * The decision, apart from where the values come from, so a test can supply them.
     *
     * @param property    the property's value, or null when unset
     * @param environment the variable's value, or null when unset
     * @return true if the property is {@code true} in any case, or the variable is
     *         {@code 1} or {@code true} in any case
     */
    static boolean on(String property, String environment) {
        return "true".equalsIgnoreCase(property)
                || "1".equals(environment) || "true".equalsIgnoreCase(environment);
    }
}
