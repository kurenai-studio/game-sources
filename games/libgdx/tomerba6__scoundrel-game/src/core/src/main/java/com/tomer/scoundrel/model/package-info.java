/**
 * The game as plain data: cards, the equipped weapon and the whole-game
 * snapshot, all immutable records.
 *
 * <p>Pure Java with no dependencies, and it stays that way: nothing here imports
 * LibGDX, the rules, or any of the observers ({@code runs}, {@code achievements},
 * {@code tutorial}, {@code audio}). A state is never changed in place — the
 * engine builds the next one from it — so any state can be held, compared or
 * rebuilt in a test without a window or a render loop.
 *
 * <p>Behaviour is not stored on a card. A {@link com.tomer.scoundrel.model.Card}
 * carries only its id and stamped stats; the rules look up the card's effect by
 * that id at resolution time, which is what keeps a state serializable.
 *
 * @see com.tomer.scoundrel.rules.ScoundrelEngine
 */
package com.tomer.scoundrel.model;
