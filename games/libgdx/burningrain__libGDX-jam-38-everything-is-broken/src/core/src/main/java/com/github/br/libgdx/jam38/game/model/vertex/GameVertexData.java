package com.github.br.libgdx.jam38.game.model.vertex;


import com.badlogic.gdx.math.Vector2;
import com.github.br.libgdx.jam38.game.model.GameVertexState;

public class GameVertexData {

    private final String name;
    private final Vector2 position;

    private GameVertexState state;
    private float energy;
    private float emissionPercent;
    private boolean isFreeze;

    public GameVertexData(
        String name,
        Vector2 position,
        float energy,
        float emissionPercent,
        GameVertexState state,
        boolean isFreeze
    ) {
        this.name = name;
        this.position = position;
        this.state = state;
        this.energy = energy;
        this.emissionPercent = emissionPercent;
        this.isFreeze = isFreeze;
    }

    public String getName() {
        return name;
    }

    public float getEnergy() {
        return energy;
    }

    public void addEnergy(float addedEnergy) {
        this.energy += addedEnergy;
    }

    public void changeEnergy(float diff) {
        this.energy += diff;
    }

    public Vector2 getPosition() {
        return position;
    }

    public GameVertexState getState() {
        return state;
    }

    public void setState(GameVertexState state) {
        this.state = state;
    }

    public float getEmissionPercent() {
        return emissionPercent;
    }

    public void setEmissionPercent(float emissionPercent) {
        this.emissionPercent = emissionPercent;
    }

    public boolean isFreeze() {
        return isFreeze;
    }

    public void setFreeze(boolean freeze) {
        isFreeze = freeze;
    }
}
