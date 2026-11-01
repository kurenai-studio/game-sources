package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;

/** When avoiding the current room is legal (Strategy — variants may relax it). */
public interface AvoidRule {

    /**
     * Whether the player may scoop the current room to the bottom of the dungeon.
     * The engine offers {@link Move.AvoidRoom} exactly when this says yes.
     *
     * @param state the game as it stands, possibly already over
     * @return true if avoiding is a legal move now
     */
    boolean canAvoid(GameState state);
}
