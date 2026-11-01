package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import org.junit.jupiter.api.Test;

import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The avoid rule Relentless plays under. */
class NeverAvoidRuleTest {

    private final AvoidRule rule = new NeverAvoidRule();

    /** Avoiding is refused even in a room the standard rule would let you avoid. */
    @Test
    void avoidingIsNeverLegalEvenInACanonicallyAvoidableRoom() {
        // Fresh, unstarted, not-previously-avoided, dungeon still has cards: exactly
        // the state StandardAvoidRule permits. NeverAvoidRule must still refuse.
        GameState avoidable = state()
                .room(potion(2), potion(3), potion(4), potion(5))
                .dungeon(potion(6), potion(7), potion(8), potion(9))
                .build();
        assertTrue(new StandardAvoidRule().canAvoid(avoidable), "sanity: standard permits this");
        assertFalse(rule.canAvoid(avoidable));
    }
}
