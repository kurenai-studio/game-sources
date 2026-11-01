package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Property/fuzz coverage. The hand-written tests pin known cases; this plays
 * many random-but-legal games across every ruleset and asserts the engine's
 * invariants hold at every step and at the end. It is the net for subtle
 * state-machine bugs a curated example would miss — a card in two places at
 * once, health drifting past the cap, a game that never terminates, or a
 * mis-signed final score. Each game is driven by a per-seed RNG, so any failure
 * reprints the offending seed and reproduces exactly.
 */
class EngineInvariantFuzzTest {

    private static final int GAMES_PER_RULESET = 400;
    private static final int STEP_LIMIT = 1000;

    /**
     * 400 random legal games under each of the three rulesets keep every
     * invariant at every step and at the end.
     */
    @Test
    void everyRulesetHoldsItsInvariantsOverManyRandomGames() {
        for (Ruleset rules : List.of(Rulesets.standard(), Rulesets.relentless(), Rulesets.frail())) {
            ScoundrelEngine engine = new ScoundrelEngine(rules);
            Set<String> deckIds = deckIds(rules);
            for (int seed = 0; seed < GAMES_PER_RULESET; seed++) {
                playAndCheck(engine, rules, deckIds, seed);
            }
        }
    }

    private void playAndCheck(ScoundrelEngine engine, Ruleset rules, Set<String> deckIds, long seed) {
        Random rng = new Random(seed);
        GameState state = engine.newGame(seed);
        Set<String> resolved = new HashSet<>();
        int steps = 0;
        while (state.status() == Status.IN_PROGRESS) {
            checkInProgressInvariants(state, rules, deckIds, seed);
            List<Move> moves = engine.legalMoves(state);
            assertFalse(moves.isEmpty(), "in-progress game offered no moves (seed " + seed + ")");
            Move move = moves.get(rng.nextInt(moves.size()));
            if (move instanceof Move.CardMove card) {
                // A card leaves play the instant it is resolved and never returns,
                // so the same id must never be resolved twice.
                assertTrue(resolved.add(card.targetCard().id()),
                        "card resolved twice: " + card.targetCard().id() + " (seed " + seed + ")");
            }
            state = engine.apply(state, move).state();
            assertTrue(++steps < STEP_LIMIT, "game did not terminate (seed " + seed + ")");
        }
        checkTerminalInvariants(state, deckIds.size(), resolved, seed);
    }

    private void checkInProgressInvariants(GameState s, Ruleset rules, Set<String> deckIds, long seed) {
        String at = " (seed " + seed + ")";
        // Health stays within (0, cap] while playing — heals cap, damage only lowers.
        assertTrue(s.health() > 0 && s.health() <= rules.healthCap(),
                "health " + s.health() + " outside (0, cap]" + at);
        // A room never exceeds its size.
        assertTrue(s.room().size() <= rules.roomSize(), "room larger than roomSize" + at);
        // No card is ever in two places at once, and every card is a real deck card.
        List<String> live = new ArrayList<>();
        s.room().forEach(c -> live.add(c.id()));
        s.dungeon().forEach(c -> live.add(c.id()));
        EquippedWeapon w = s.weapon();
        if (w != null) {
            live.add(w.weapon().id());
            w.slain().forEach(c -> live.add(c.id()));
        }
        assertEquals(live.size(), new HashSet<>(live).size(), "a card is in two places at once" + at);
        assertTrue(deckIds.containsAll(live), "an unknown card appeared" + at);
        // The weapon only ever stacks monsters.
        if (w != null) {
            w.slain().forEach(c ->
                    assertEquals(CardType.MONSTER, c.type(), "a non-monster on the weapon" + at));
        }
    }

    private void checkTerminalInvariants(GameState s, int deckSize, Set<String> resolved, long seed) {
        String at = " (seed " + seed + ")";
        assertTrue(s.score() != null, "terminal state has no score" + at);
        if (s.status() == Status.WON) {
            assertTrue(s.room().isEmpty() && s.dungeon().isEmpty(), "won with cards left" + at);
            assertTrue(s.health() > 0, "won at non-positive health" + at);
            assertTrue(s.score() > 0, "won with a non-positive score" + at);
            // Clearing the dungeon means every card was resolved exactly once.
            assertEquals(deckSize, resolved.size(), "won without resolving every card" + at);
        } else {
            assertEquals(Status.LOST, s.status(), "unexpected terminal status" + at);
            assertTrue(s.health() <= 0, "lost at positive health" + at);
            assertTrue(s.score() <= 0, "lost with a positive score" + at);
        }
    }

    private static Set<String> deckIds(Ruleset rules) {
        Set<String> ids = new HashSet<>();
        rules.deck().cards().forEach(def -> ids.add(def.card().id()));
        return ids;
    }
}
