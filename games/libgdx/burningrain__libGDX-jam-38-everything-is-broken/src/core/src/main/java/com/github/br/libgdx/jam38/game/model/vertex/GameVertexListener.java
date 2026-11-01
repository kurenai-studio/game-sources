package com.github.br.libgdx.jam38.game.model.vertex;

import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.GameVertexState;

public interface GameVertexListener {

    void setFreeze(CalculateVertexProxy calculateVertexProxy, boolean isFreeze);

    void changeEnergy(CalculateVertexProxy calculateVertexProxy, float diff);

    void addEnergy(GameVertex from, GameVertex to, float addedEnergy);

    void setState(CalculateVertexProxy calculateVertexProxy, GameVertexState gameVertexState);

    void removeNeighbour(CalculateVertexProxy calculateVertexProxy, GameVertex to);

    void addNeighbour(CalculateVertexProxy calculateVertexProxy, GameVertex to);

    void calculateCurrent(
        CalculateVertexProxy calculateVertexProxy,
        float inEnergy,
        float outEnergy,
        Array<GameVertex.AddedEnergy> outEnergyArray
    );

}
