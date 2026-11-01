package com.micro1.shadowclone;

/**
 * Run-wide performance counters shown on the Victory screen (rubric item 16 / prompt: completion
 * time, recordings, clones, puzzles solved, deaths, rank). Lives on {@link ShadowCloneGame} so it
 * persists across level transitions and is reset when a new run starts.
 */
public final class GameStats {

    public int recordingsMade;
    public int clonesUsed;
    public int switchesActivated;
    public int puzzlesSolved;
    public int deaths;
    public float elapsedTime;      // seconds of active play across the run
    public static final int TOTAL_PUZZLES = 12;

    public void reset() {
        recordingsMade = 0;
        clonesUsed = 0;
        switchesActivated = 0;
        puzzlesSolved = 0;
        deaths = 0;
        elapsedTime = 0f;
    }

    /** A letter rank from puzzles solved / deaths, mirroring the S / A / B / C badge in the refs. */
    public String rank() {
        if (puzzlesSolved < TOTAL_PUZZLES) return "C";
        if (deaths == 0) return "S";
        if (deaths <= 2) return "A";
        if (deaths <= 5) return "B";
        return "C";
    }

    /** mm:ss.cc form for the elapsed run time. */
    public String timeString() {
        int totalCenti = Math.max(0, (int) (elapsedTime * 100f));
        int minutes = totalCenti / 6000;
        int seconds = (totalCenti / 100) % 60;
        int centi = totalCenti % 100;
        return String.format("%02d:%02d.%02d", minutes, seconds, centi);
    }
}
