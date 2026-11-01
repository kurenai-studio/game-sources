package com.github.br.libgdx.jam38.game.model.action.edge;

import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;

public class GameEdge {

    private final GameVertex from;
    private final GameVertex to;

    public GameEdge(GameVertex from, GameVertex to) {
        this.from = from;
        this.to = to;
    }

    public GameVertex getFrom() {
        return from;
    }

    public GameVertex getTo() {
        return to;
    }

}
