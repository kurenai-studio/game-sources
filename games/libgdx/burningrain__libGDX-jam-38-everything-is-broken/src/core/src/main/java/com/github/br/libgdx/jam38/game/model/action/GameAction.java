package com.github.br.libgdx.jam38.game.model.action;

public interface GameAction {

    boolean isVertexAction();

    boolean isEdgeAction();

    int getTimeCost();

    GameVertexAction asVertexAction();
    GameEdgeAction asEdgeAction();

}
