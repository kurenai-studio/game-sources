package com.tomer.scoundrel.screens;

/**
 * Which clock a card of the room is on while the board is moving.
 *
 * <p>Resolving a card sets three things going, and they are not one thing:
 * what happens to the card that left, the survivors re-centring around the gap
 * it made, and whatever the dungeon sends up to replace it. Running all three
 * in sequence would make a single resolve take the best part of a second and
 * read as three separate events; running all three at once flies a fresh card
 * over the top of the one being killed.
 *
 * <p>So the room <b>closes</b> alongside the effect and the <b>deal</b> waits
 * for it. The gap shuts as the monster dies, which is one event, and only then
 * does the dungeon offer up the next card, which is another.
 */
final class RoomMotion {

    /** What a room card is doing this frame. */
    enum Phase {
        /** Sitting in its slot; nothing is happening to it. */
        RESTING,
        /** Not on the table yet — still in the dungeon, waiting out the effect. */
        HIDDEN,
        /** Re-centring as the room closes up around a resolved card. */
        SLIDING,
        /** Coming up out of the dungeon into its slot. */
        DEALING
    }

    private RoomMotion() {
    }

    /**
     * Which phase a room card is in, from what the board knows about it.
     *
     * @param wasOnBoard     whether the card was already face-up before this move
     * @param effectRunning  whether something is still happening to the resolved card
     * @param closing        whether the survivors are re-centring
     * @param dealing        whether the dungeon still has cards to send up
     * @return the card's phase: an old card rests or slides, a new one hides, then deals
     */
    static Phase of(boolean wasOnBoard, boolean effectRunning, boolean closing, boolean dealing) {
        if (wasOnBoard) {
            return closing ? Phase.SLIDING : Phase.RESTING;
        }
        if (effectRunning) {
            return Phase.HIDDEN;
        }
        return dealing ? Phase.DEALING : Phase.RESTING;
    }
}
