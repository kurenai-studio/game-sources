package com.github.br.libgdx.jam38.game.model.action;

import com.badlogic.gdx.utils.GdxRuntimeException;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;

public abstract class GameVertexAction implements GameAction {

    private final String target;

    public boolean isVertexAction() {
        return true;
    }

    public boolean isEdgeAction() {
        return false;
    }

    public GameVertexAction asVertexAction() {
        return this;
    }

    public GameEdgeAction asEdgeAction() {
        throw new GdxRuntimeException("This is VertexAction, not EdgeAction");
    }

    public GameVertexAction(String target) {
        this.target = target;
    }

    public String getTargetName() {
        return target;
    }

    public abstract void execute(GameVertex gameVertex);

}
