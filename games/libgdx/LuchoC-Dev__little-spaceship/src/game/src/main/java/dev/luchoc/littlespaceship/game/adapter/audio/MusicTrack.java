package dev.luchoc.littlespaceship.game.adapter.audio;

/**
 * The looping tracks {@link AudioSystem} can play. There is no menu track: {@code
 * docs/planning/02-mvp-functional-spec.md}'s audiovisual section names only "main level music" and
 * "music change when the boss begins" — the menu is silent, and silence is itself the audible
 * change the phase's acceptance criterion asks for when a run ends and the player lands back there.
 */
public enum MusicTrack {

    /** The level's own loop, playing for the whole run until the boss appears. */
    LEVEL("level.wav"),

    /** Swapped in the instant {@code WorldView.bossStatus().present()} turns true, from {@link
     * AudioDirector#update}. */
    BOSS("boss.wav");

    private final String fileName;

    MusicTrack(String fileName) {
        this.fileName = fileName;
    }

    /** @return the file name under {@code assets/audio/music/}, matching {@code GenerateAudio}'s output */
    public String fileName() {
        return fileName;
    }
}
