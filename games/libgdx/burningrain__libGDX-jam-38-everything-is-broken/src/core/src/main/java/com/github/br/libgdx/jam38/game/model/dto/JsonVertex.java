package com.github.br.libgdx.jam38.game.model.dto;

import com.github.br.libgdx.jam38.game.model.GameVertexState;

public class JsonVertex {

    private String name;
    private int x;
    private int y;

    private int energy;
    private float emissionPercent;
    private GameVertexState state;
    private boolean isFreeze;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getX() {
        return x;
    }

    public void setX(int x) {
        this.x = x;
    }

    public int getY() {
        return y;
    }

    public void setY(int y) {
        this.y = y;
    }

    public int getEnergy() {
        return energy;
    }

    public void setEnergy(int energy) {
        this.energy = energy;
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
