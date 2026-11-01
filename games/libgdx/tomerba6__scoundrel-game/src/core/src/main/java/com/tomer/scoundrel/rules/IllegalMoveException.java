package com.tomer.scoundrel.rules;

/** Thrown when a move is applied that {@code legalMoves} does not offer. */
public class IllegalMoveException extends RuntimeException {

    /**
     * A rejected move. Unchecked: a correct caller only applies moves it was offered.
     *
     * @param message what was rejected, naming the move
     */
    public IllegalMoveException(String message) {
        super(message);
    }
}
