package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.Move.TakePotion;
import org.junit.jupiter.api.Test;

import java.util.List;

import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static com.tomer.scoundrel.rules.StateBuilder.state;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The shipped difficulty variants: same engine, different Ruleset instances. */
class VariantRulesetsTest {

    /** Relentless is Standard in every constant, with an avoid rule that never allows it. */
    @Test
    void relentlessMatchesStandardButForbidsAvoiding() {
        Ruleset standard = Rulesets.standard();
        Ruleset relentless = Rulesets.relentless();
        assertEquals(standard.startingHealth(), relentless.startingHealth());
        assertEquals(standard.healthCap(), relentless.healthCap());
        assertEquals(standard.roomSize(), relentless.roomSize());
        assertEquals(standard.cardsResolvedPerTurn(), relentless.cardsResolvedPerTurn());
        assertEquals(standard.potionsPerTurn(), relentless.potionsPerTurn());
        assertTrue(relentless.avoidRule() instanceof NeverAvoidRule);
        assertTrue(relentless.scoring() instanceof StandardScoring);
        assertTrue(relentless.deck() instanceof StandardDeck);
    }

    /** Relentless offers no avoid move, even on the first full room. */
    @Test
    void relentlessOffersNoAvoidMoveEvenOnAFreshFullRoom() {
        ScoundrelEngine engine = new ScoundrelEngine(Rulesets.relentless());
        GameState g = engine.newGame(42L);
        assertFalse(engine.legalMoves(g).contains(new Move.AvoidRoom()));
    }

    /** Frail starts at 14 health and caps there, and still allows avoiding. */
    @Test
    void frailStartsAndCapsAtFourteen() {
        Ruleset frail = Rulesets.frail();
        assertEquals(14, frail.startingHealth());
        assertEquals(14, frail.healthCap());
        assertTrue(frail.avoidRule() instanceof StandardAvoidRule);
        assertEquals(14, new ScoundrelEngine(frail).newGame(1L).health());
    }

    /** Frail's healing stops at its cap of 14. */
    @Test
    void frailHealingClipsToItsLowerCap() {
        ScoundrelEngine engine = new ScoundrelEngine(Rulesets.frail());
        GameState s = state().health(10).room(potion(9), weapon(2), weapon(3), weapon(4)).build();
        GameState next = engine.apply(s, new TakePotion(potion(9))).state();
        assertEquals(14, next.health()); // 10 + 9 = 19, clipped to the frail cap
    }

    /** Each of the three rulesets plays a seeded game through to a score. */
    @Test
    void everyModePlaysAFullSeededGameToTermination() {
        for (Ruleset rules : List.of(Rulesets.standard(), Rulesets.relentless(), Rulesets.frail())) {
            ScoundrelEngine engine = new ScoundrelEngine(rules);
            GameState g = engine.newGame(42L);
            int steps = 0;
            while (g.status() == Status.IN_PROGRESS) {
                List<Move> moves = engine.legalMoves(g);
                assertFalse(moves.isEmpty(), "in-progress game must offer moves");
                g = engine.apply(g, moves.get(steps % moves.size())).state();
                assertTrue(++steps < 500, "game did not terminate");
            }
            assertNotNull(g.score());
        }
    }
}
