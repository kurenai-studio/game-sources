package com.github.br.libgdx.jam38.game.model.action;

import com.badlogic.gdx.utils.GdxRuntimeException;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;

public abstract class GameEdgeAction implements GameAction {

    private final String from;
    private final String to;

    public GameEdgeAction(String from, String to) {
        this.from = from;
        this.to = to;
    }

    public boolean isVertexAction() {
        return false;
    }

    public boolean isEdgeAction() {
        return true;
    }

    public GameVertexAction asVertexAction() {
        throw new GdxRuntimeException("This is VertexAction, not EdgeAction");
    }

    public GameEdgeAction asEdgeAction() {
        return this;
    }

    public String getFrom() {
        return from;
    }

    public String getTo() {
        return to;
    }

    public abstract void execute(GameVertex from, GameVertex to);

}
