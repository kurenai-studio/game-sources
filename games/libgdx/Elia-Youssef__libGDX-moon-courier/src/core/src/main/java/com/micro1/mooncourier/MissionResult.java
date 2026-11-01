package com.micro1.mooncourier;

/**
 * Immutable snapshot of a finished mission, handed to the Victory or Game Over screen so they can
 * report the outcome (final fuel, score, time). Keeps the ending screens independent of the live
 * {@link MissionWorld}.
 */
public final class MissionResult {

    public final boolean delivered;
    public final int fuelPercent;
    public final int score;
    public final float timeSeconds;

    public MissionResult(boolean delivered, int fuelPercent, int score, float timeSeconds) {
        this.delivered = delivered;
        this.fuelPercent = fuelPercent;
        this.score = score;
        this.timeSeconds = timeSeconds;
    }

    /** Builds a result from the world at the moment the mission ended. */
    public static MissionResult from(MissionWorld world) {
        return new MissionResult(
            world.getState() == GameState.WON,
            world.getFuelPercent(),
            world.getScore(),
            world.getElapsed());
    }

    /** Formats a duration in seconds as mm:ss. */
    public static String formatTime(float seconds) {
        int total = Math.max(0, (int) seconds);
        int m = total / 60;
        int s = total % 60;
        return twoDigits(m) + ":" + twoDigits(s);
    }

    private static String twoDigits(int value) {
        return value < 10 ? "0" + value : Integer.toString(value);
    }
}
