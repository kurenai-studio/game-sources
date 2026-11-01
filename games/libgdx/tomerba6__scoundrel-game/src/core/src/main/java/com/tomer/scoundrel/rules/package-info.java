/**
 * The rules engine: moves, card effects, rulesets and the turn loop.
 *
 * <p>{@link com.tomer.scoundrel.rules.ScoundrelEngine#apply} takes a state and
 * a move and returns a {@link com.tomer.scoundrel.rules.MoveResult}: the next
 * state and the {@link com.tomer.scoundrel.rules.GameEvent events} that
 * happened. Nothing is pushed out of here. Achievements, run stats, the
 * tutorial, the audio and the screens all read those events from outside, and
 * this package imports none of them.
 *
 * <p>Pure, deterministic Java with no LibGDX: a game is fully decided by its
 * ruleset and seed, and every rule can be tested headlessly. The engine
 * hardcodes only the turn shape. Every constant and strategy comes from the
 * injected {@link com.tomer.scoundrel.rules.Ruleset}, and what a card does
 * comes from its {@link com.tomer.scoundrel.rules.CardEffect}, never from a
 * switch on suit. A difficulty mode is a new
 * {@link com.tomer.scoundrel.rules.Rulesets} factory plus a
 * {@link com.tomer.scoundrel.rules.GameModes} entry, not engine code.
 *
 * <p>The edge-case decisions (partial rooms, wasted potions, the potion-bonus
 * win score, avoiding with an empty dungeon) are recorded in
 * {@code docs/design.md}.
 *
 * @see com.tomer.scoundrel.model
 */
package com.tomer.scoundrel.rules;
