package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.EquippedWeapon;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

/**
 * The pure, deterministic rules engine. The turn structure is fixed here
 * (deal, resolve, carryover/refill, avoid, end); everything rule-shaped is
 * delegated to the injected {@link Ruleset} and the cards' effects.
 * {@code apply} validates against {@code legalMoves} and never mutates its
 * input state.
 */
public final class ScoundrelEngine {

    private final Ruleset rules;

    /**
     * An engine for one ruleset; it keeps no game state, so one engine can run any
     * number of games.
     *
     * @param rules the constants, strategies and deck every game is played with
     */
    public ScoundrelEngine(Ruleset rules) {
        this.rules = rules;
    }

    /**
     * A new game with the deck shuffled reproducibly from the seed.
     *
     * @param seed any value; the same seed and ruleset always deal the same dungeon
     * @return the opening state: the first room dealt, full health, in progress
     * @see java.util.Collections#shuffle(List, Random)
     */
    public GameState newGame(long seed) {
        List<Card> cards = new ArrayList<>();
        for (CardDefinition def : rules.deck().cards()) {
            cards.add(def.card());
        }
        Collections.shuffle(cards, new Random(seed));
        return newGame(cards);
    }

    /**
     * Test hook: a new game with an exact dungeon order, index 0 on top. The
     * tutorial's scripted deck comes in this way too.
     *
     * @param orderedDungeon the cards to play, top first; copied, and not checked against
     *                       the ruleset's deck
     * @return the opening state: the first room dealt from the top, full health, in progress
     */
    public GameState newGame(List<Card> orderedDungeon) {
        List<Card> dungeon = new ArrayList<>(orderedDungeon);
        List<Card> room = new ArrayList<>();
        refill(room, dungeon);
        return new GameState(dungeon, room, null, rules.startingHealth(), 0,
                0, false, null, Status.IN_PROGRESS, null);
    }

    /**
     * Every move the player may make now: avoiding (if the avoid rule allows it),
     * then each room card's moves, in room order.
     *
     * @param state the game as it stands
     * @return the moves {@link #apply} will accept; empty once the game is over
     */
    public List<Move> legalMoves(GameState state) {
        if (state.status() != Status.IN_PROGRESS) {
            return List.of();
        }
        List<Move> moves = new ArrayList<>();
        if (rules.avoidRule().canAvoid(state)) {
            moves.add(new Move.AvoidRoom());
        }
        for (Card card : state.room()) {
            moves.addAll(effectFor(card).legalMoves(card, state));
        }
        return List.copyOf(moves);
    }

    /**
     * Plays one move. Resolves the card through its effect, then runs the turn
     * loop: a loss freezes the state; the ruleset's cards-per-turn (or an emptied
     * room) end the turn and refill the room; an empty room and dungeon is a win. A
     * finished game is scored before it is returned.
     *
     * @param state the game as it stands; not modified
     * @param move  one of {@link #legalMoves legalMoves(state)}
     * @return the next state and the events of this move, in order
     * @throws IllegalMoveException if {@code move} is not currently legal, including any
     *                              move once the game is over
     */
    public MoveResult apply(GameState state, Move move) {
        if (!legalMoves(state).contains(move)) {
            throw new IllegalMoveException("Illegal move " + move);
        }
        return switch (move) {
            case Move.AvoidRoom ignored -> applyAvoid(state);
            case Move.CardMove cardMove -> applyCardMove(state, cardMove);
        };
    }

    private MoveResult applyAvoid(GameState state) {
        List<Card> dungeon = new ArrayList<>(state.dungeon());
        dungeon.addAll(state.room());
        List<Card> room = new ArrayList<>();
        refill(room, dungeon);
        GameState next = new GameState(dungeon, room, state.weapon(), state.health(), 0,
                0, true, state.lastResolvedCard(), Status.IN_PROGRESS, null);
        List<GameEvent> events = List.of(
                new GameEvent.RoomAvoided(state.room()),
                new GameEvent.RoomDealt(room));
        return new MoveResult(next, events);
    }

    private MoveResult applyCardMove(GameState state, Move.CardMove move) {
        Card card = move.targetCard();
        ResolutionContext ctx = new ResolutionContext(rules, state);
        effectFor(card).resolve(move, ctx);

        List<Card> dungeon = new ArrayList<>(state.dungeon());
        List<Card> room = new ArrayList<>(state.room());
        room.remove(card);
        int health = ctx.health();
        EquippedWeapon weapon = ctx.weapon();
        int potionsUsed = ctx.potionsUsedThisRoom();
        int resolvedThisTurn = state.cardsResolvedThisTurn() + 1;
        boolean previousAvoided = state.previousRoomAvoided();
        List<GameEvent> events = new ArrayList<>(ctx.events());

        if (health <= 0) {
            // Loss freezes the state as-is: no refill, raw (negative) health kept.
            return terminal(new GameState(dungeon, room, weapon, health, potionsUsed,
                    resolvedThisTurn, previousAvoided, card, Status.LOST, null), events);
        }

        if (resolvedThisTurn >= rules.cardsResolvedPerTurn() || room.isEmpty()) {
            // Turn over: the leftover card (if any) carries into the next room.
            // A room that started partial ends only when it empties, so its
            // cards share one turn (and one potion allowance).
            refill(room, dungeon);
            potionsUsed = 0;
            resolvedThisTurn = 0;
            previousAvoided = false;
            if (!room.isEmpty()) {
                events.add(new GameEvent.RoomDealt(List.copyOf(room)));
            }
        }

        if (room.isEmpty() && dungeon.isEmpty()) {
            return terminal(new GameState(dungeon, room, weapon, health, potionsUsed,
                    resolvedThisTurn, previousAvoided, card, Status.WON, null), events);
        }

        GameState next = new GameState(dungeon, room, weapon, health, potionsUsed,
                resolvedThisTurn, previousAvoided, card, Status.IN_PROGRESS, null);
        return new MoveResult(next, events);
    }

    private MoveResult terminal(GameState unscored, List<GameEvent> events) {
        int score = rules.scoring().score(unscored, rules);
        GameState scored = new GameState(unscored.dungeon(), unscored.room(),
                unscored.weapon(), unscored.health(), unscored.potionsUsedThisRoom(),
                unscored.cardsResolvedThisTurn(), unscored.previousRoomAvoided(),
                unscored.lastResolvedCard(), unscored.status(), score);
        events.add(unscored.status() == Status.WON
                ? new GameEvent.GameWon(score)
                : new GameEvent.GameLost(score));
        return new MoveResult(scored, events);
    }

    private void refill(List<Card> room, List<Card> dungeon) {
        while (room.size() < rules.roomSize() && !dungeon.isEmpty()) {
            room.add(dungeon.remove(0));
        }
    }

    private CardEffect effectFor(Card card) {
        return rules.deck().definition(card.id()).effect();
    }
}
