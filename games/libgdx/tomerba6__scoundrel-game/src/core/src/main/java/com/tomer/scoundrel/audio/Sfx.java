package com.tomer.scoundrel.audio;

/**
 * One sound effect, chosen and ready to play: which file, at what pitch, and
 * how loud relative to the file itself. Volume is at most 1 — a variation only
 * ever makes a play quieter, never louder than the file was mastered.
 *
 * @param sound  which moment this is, for logging and for collapsing on a skip
 * @param file   the file's name without directory or extension, e.g. {@code blade_heavy_2}
 * @param pitch  the playback rate, 1 as rendered; weighted sounds sit within a few percent
 * @param volume the gain relative to the file, 0 to 1
 */
public record Sfx(Sound sound, String file, float pitch, float volume) {

    /** Where the sound-effect files ship, relative to the asset root. */
    public static final String DIRECTORY = "audio/sfx/";
    /** Every sound-effect file is a WAV. */
    public static final String EXTENSION = ".wav";

    /**
     * The internal asset path of this sound's file.
     *
     * @return {@link #DIRECTORY} + {@code file} + {@link #EXTENSION}
     */
    public String path() {
        return DIRECTORY + file + EXTENSION;
    }
}
