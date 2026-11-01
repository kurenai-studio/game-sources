package com.github.br.libgdx.jam38.game.model;

import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.action.GameAction;

public final class GameDelta {

    private final boolean isTimeOver;
    private final boolean isGameVictory;
    private final boolean isGameOver;
    private final Array<VertexDelta> vertexDelta;
    private final int timerSec;
    private final Array<GameAction> appliedActions;

    public GameDelta
        (boolean isTimeOver,
         int timerSec,
         boolean isGameVictory,
         boolean isGameOver,
         Array<VertexDelta> vertexDelta,
         Array<GameAction> appliedActions
        ) {
        this.isTimeOver = isTimeOver;
        this.isGameVictory = isGameVictory;
        this.isGameOver = isGameOver;
        this.vertexDelta = vertexDelta;
        this.timerSec = timerSec;
        this.appliedActions = appliedActions;
    }

    public boolean isTimeOver() {
        return isTimeOver;
    }

    public boolean isGameVictory() {
        return isGameVictory;
    }

    public boolean isGameOver() {
        return isGameOver;
    }

    public Array<VertexDelta> getVertexDelta() {
        return vertexDelta;
    }

    public int getTimerSec() {
        return timerSec;
    }

    public Array<GameAction> getAppliedActions() {
        return appliedActions;
    }

}
