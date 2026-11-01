package com.github.br.libgdx.jam38.game.screens.ui;

import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.GameVertexState;
import com.github.br.libgdx.jam38.game.model.vertex.CalculateVertexProxy;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertexListener;

public abstract class EdgeGameVertexListener implements GameVertexListener {
    @Override
    public void setFreeze(CalculateVertexProxy calculateVertexProxy, boolean isFreeze) {

    }

    @Override
    public void changeEnergy(CalculateVertexProxy calculateVertexProxy, float diff) {

    }

    @Override
    public abstract void addEnergy(GameVertex from, GameVertex to, float addedEnergy);

    @Override
    public void setState(CalculateVertexProxy calculateVertexProxy, GameVertexState gameVertexState) {

    }

    @Override
    public void removeNeighbour(CalculateVertexProxy calculateVertexProxy, GameVertex to) {

    }

    @Override
    public void addNeighbour(CalculateVertexProxy calculateVertexProxy, GameVertex to) {

    }

    @Override
    public void calculateCurrent(CalculateVertexProxy calculateVertexProxy, float inEnergy, float outEnergy, Array<GameVertex.AddedEnergy> outEnergyArray) {

    }

}
