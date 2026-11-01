package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;

/**
 * Base Scoundrel avoiding: only before any card in the room is resolved,
 * never two rooms in a row, and only while the dungeon has cards — with an
 * empty dungeon the same room would just be re-dealt, so avoiding is a no-op
 * and therefore illegal.
 */
public final class StandardAvoidRule implements AvoidRule {

    /** Creates the rule; it holds no state. */
    public StandardAvoidRule() {
    }

    @Override
    public boolean canAvoid(GameState state) {
        return state.status() == Status.IN_PROGRESS
                && !state.roomResolutionStarted()
                && !state.previousRoomAvoided()
                && !state.dungeon().isEmpty();
    }
}
