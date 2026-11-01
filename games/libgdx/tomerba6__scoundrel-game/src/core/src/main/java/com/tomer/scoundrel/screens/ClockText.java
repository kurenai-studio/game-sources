package com.tomer.scoundrel.screens;

/**
 * The one run-duration formatter — pure, so it is unit tested and shared by the
 * live HUD timer, the end screen, and the records ledger, which must all read a
 * time the same way. Under an hour it is {@code M:SS}; past an hour it drops to
 * the coarser {@code Hh Mm}.
 */
final class ClockText {

    private ClockText() {
    }

    /**
     * A duration as the player reads it.
     *
     * @param seconds whole seconds, 0 or more
     * @return {@code M:SS} under an hour (e.g. {@code 7:05}), {@code Hh Mm} from an hour up
     */
    static String format(long seconds) {
        long hours = seconds / 3600;
        long minutes = (seconds % 3600) / 60;
        long rest = seconds % 60;
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + ":" + String.format("%02d", rest);
    }
}
