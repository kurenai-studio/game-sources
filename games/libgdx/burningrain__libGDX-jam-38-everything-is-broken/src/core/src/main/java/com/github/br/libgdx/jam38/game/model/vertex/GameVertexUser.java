package com.github.br.libgdx.jam38.game.model.vertex;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.GameVertexState;
import com.github.br.libgdx.jam38.game.model.VertexDelta;

public class GameVertexUser implements GameVertex {

    @Override
    public Array<GameVertex> getNeighbours() {
        return null;
    }

    @Override
    public void addNeighbour(GameVertex to) {

    }

    @Override
    public void removeNeighbour(GameVertex to) {

    }

    @Override
    public void setState(GameVertexState gameVertexState) {

    }

    @Override
    public GameVertexState getState() {
        return null;
    }

    @Override
    public void calculateCurrent() {

    }

    @Override
    public VertexDelta calculateFinal() {
        return null;
    }

    @Override
    public String getName() {
        return "";
    }

    @Override
    public float getEnergy() {
        return 0;
    }

    @Override
    public void addEnergy(GameVertex from, float addedEnergy) {

    }

    @Override
    public void changeEnergy(float diff) {

    }

    @Override
    public Vector2 getPosition() {
        return null;
    }

    @Override
    public float getDiffEnergy() {
        return 0;
    }

    @Override
    public boolean isFreeze() {
        return false;
    }

    @Override
    public void setFreeze(boolean isFreeze) {

    }

    @Override
    public void addGameVertexListener(GameVertexListener gameVertexListener) {

    }

    @Override
    public void removeListener(GameVertexListener gameVertexListener) {

    }
}
