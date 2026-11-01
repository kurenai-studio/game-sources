package com.github.br.libgdx.jam38.game.model;

import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertexData;

public class VertexDelta {

    private final GameVertexData target;
    private final float diff;
    private final float inEnergy;
    private final float outEnergy;
    private final Array<GameVertex.AddedEnergy> outEnergyArray;

    public VertexDelta(
        GameVertexData target,
        float diff,
        float inEnergy,
        float outEnergy,
        Array<GameVertex.AddedEnergy> outEnergyArray
    ) {
        this.target = target;
        this.diff = diff;
        this.inEnergy = inEnergy;
        this.outEnergy = outEnergy;
        this.outEnergyArray = outEnergyArray;
    }

    public GameVertexData getTarget() {
        return target;
    }

    public float getDiff() {
        return diff;
    }

    public float getInEnergy() {
        return inEnergy;
    }

    public float getOutEnergy() {
        return outEnergy;
    }

    public Array<GameVertex.AddedEnergy> getOutEnergyArray() {
        return outEnergyArray;
    }

}
