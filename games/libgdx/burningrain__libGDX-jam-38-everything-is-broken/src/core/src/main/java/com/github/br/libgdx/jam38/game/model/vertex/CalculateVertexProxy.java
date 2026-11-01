package com.github.br.libgdx.jam38.game.model.vertex;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.github.br.libgdx.jam38.game.model.GameVertexState;
import com.github.br.libgdx.jam38.game.model.VertexDelta;

public class CalculateVertexProxy implements GameVertex {

    private final GameVertexData target;
    private final Array<GameVertex> neighbours = new Array<>();

    private float outEnergy = 0f;
    private float inEnergy = 0f;
    private float diffEnergy = 0f;
    private Array<AddedEnergy> outEnergyArray = null;

    // observer
    private final Array<GameVertexListener> gameVertexListeners = new Array<>();

    public CalculateVertexProxy(GameVertexData target) {
        this.target = target;
    }

    @Override
    public void calculateCurrent() {
        if (GameVertexState.EMITTER == target.getState()) {
            outEnergy = Math.max(target.getEnergy() * target.getEmissionPercent(), 2.5f);
            Array<GameVertex> neighbours = getNeighbours();

            float sum = 0f;
            for (GameVertex neighbour : neighbours) {
                if (neighbour.isFreeze()) {
                    continue;
                }

                sum += neighbour.getEnergy();
            }

            outEnergyArray = new Array<>(neighbours.size);
            for (GameVertex neighbour : neighbours) {
                if (neighbour.isFreeze()) {
                    continue;
                }

                float addedEnergy = outEnergy * neighbour.getEnergy() / sum;
                neighbour.addEnergy(this, addedEnergy);
                outEnergyArray.add(new AddedEnergy(neighbour, addedEnergy));
            }

            for (GameVertexListener gameVertexListener : gameVertexListeners) {
                gameVertexListener.calculateCurrent(this, inEnergy, outEnergy, outEnergyArray);
            }
        } else if (target.isFreeze()) {
            outEnergy = 1;
        }
    }

    @Override
    public VertexDelta calculateFinal() {
        diffEnergy = inEnergy - outEnergy;
        target.changeEnergy(diffEnergy);

        VertexDelta vertexDelta = new VertexDelta(target, diffEnergy, inEnergy, outEnergy, outEnergyArray);
        inEnergy = 0f;
        outEnergy = 0f;
        outEnergyArray = null;

        return vertexDelta;
    }

    @Override
    public Array<GameVertex> getNeighbours() {
        return neighbours;
    }

    @Override
    public void addNeighbour(GameVertex to) {
        neighbours.add(to);

        for (GameVertexListener gameVertexListener : gameVertexListeners) {
            gameVertexListener.addNeighbour(this, to);
        }

    }

    @Override
    public void removeNeighbour(GameVertex to) {
        neighbours.removeValue(to, true);

        for (GameVertexListener gameVertexListener : gameVertexListeners) {
            gameVertexListener.removeNeighbour(this, to);
        }
    }

    @Override
    public void setState(GameVertexState gameVertexState) {
        target.setState(gameVertexState);

        for (GameVertexListener gameVertexListener : gameVertexListeners) {
            gameVertexListener.setState(this, gameVertexState);
        }
    }

    @Override
    public GameVertexState getState() {
        return target.getState();
    }

    @Override
    public String getName() {
        return target.getName();
    }

    @Override
    public float getEnergy() {
        return target.getEnergy();
    }

    @Override
    public void addEnergy(GameVertex from, float addedEnergy) {
        inEnergy += addedEnergy;

        for (GameVertexListener gameVertexListener : gameVertexListeners) {
            gameVertexListener.addEnergy(from, this, addedEnergy);
        }
    }

    @Override
    public void changeEnergy(float diff) {
        target.changeEnergy(diff);

        for (GameVertexListener gameVertexListener : gameVertexListeners) {
            gameVertexListener.changeEnergy(this, diff);
        }
    }

    @Override
    public Vector2 getPosition() {
        return target.getPosition();
    }

    @Override
    public float getDiffEnergy() {
        return diffEnergy;
    }

    @Override
    public boolean isFreeze() {
        return target.isFreeze();
    }

    @Override
    public void setFreeze(boolean isFreeze) {
        target.setFreeze(isFreeze);

        for (GameVertexListener gameVertexListener : gameVertexListeners) {
            gameVertexListener.setFreeze(this, isFreeze);
        }
    }

    public void addGameVertexListener(GameVertexListener gameVertexListener) {
        this.gameVertexListeners.add(gameVertexListener);
    }

    public void removeListener(GameVertexListener gameVertexListener) {
        this.gameVertexListeners.removeValue(gameVertexListener, true);
    }

}
