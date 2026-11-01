package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;

/**
 * The Relentless variant's avoid rule: avoiding is never legal, so every room
 * must be faced. A pure strategy swap — the engine's turn loop is unchanged.
 */
public final class NeverAvoidRule implements AvoidRule {

    /** Creates the rule; it holds no state. */
    public NeverAvoidRule() {
    }

    @Override
    public boolean canAvoid(GameState state) {
        return false;
    }
}
