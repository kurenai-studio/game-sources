package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.model.Status;
import com.tomer.scoundrel.rules.GameEvent;
import com.tomer.scoundrel.rules.MoveResult;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;

/** Minimal fixtures: the recorder only reads events, so one dummy state serves all. */
final class RunsTestData {

    /** An empty in-progress state at 20 health; the recorder never reads it. */
    static final GameState DUMMY_STATE = new GameState(
            List.of(), List.of(), null, 20, 0, 0, false, null, Status.IN_PROGRESS, null);

    private RunsTestData() {
    }

    /**
     * A move result carrying these events over the dummy state.
     *
     * @param events the events, in order
     * @return the result
     * @throws NullPointerException if an event is null
     */
    static MoveResult result(GameEvent... events) {
        return new MoveResult(DUMMY_STATE, List.of(events));
    }

    /**
     * A monster card.
     *
     * @param id    its id, as in {@code "JC"}
     * @param value its value; not checked
     * @return the card
     */
    static Card monster(String id, int value) {
        return new Card(id, CardType.MONSTER, value);
    }

    /**
     * A weapon card with a diamond id.
     *
     * @param value its value; not checked
     * @return the card, its id {@code value + "D"}
     */
    static Card weapon(int value) {
        return new Card(value + "D", CardType.WEAPON, value);
    }

    /**
     * A potion card with a heart id.
     *
     * @param value its value; not checked
     * @return the card, its id {@code value + "H"}
     */
    static Card potion(int value) {
        return new Card(value + "H", CardType.POTION, value);
    }

    /**
     * A clock that returns the given instants in order (last one repeats).
     *
     * @param instants the instants to return, in order; at least one
     * @return a UTC clock that returns each in turn, then the last forever
     */
    static Clock sequenceClock(Instant... instants) {
        return new Clock() {
            private int next;

            @Override
            public Instant instant() {
                return instants[Math.min(next++, instants.length - 1)];
            }

            @Override
            public ZoneId getZone() {
                return ZoneOffset.UTC;
            }

            @Override
            public Clock withZone(ZoneId zone) {
                return this;
            }
        };
    }
}
